package com.acekanner.omr

import com.acekanner.app.omr.core.PointMm
import com.acekanner.app.omr.core.SheetLayout
import java.io.File
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.random.Random
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfByte
import org.opencv.core.MatOfInt
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Rect
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import org.opencv.objdetect.Objdetect
import org.opencv.objdetect.QRCodeEncoder

/** How a student marked a bubble. */
enum class MarkStyle {
    /** No. 2 pencil, fully shaded (graphite texture). */
    PENCIL,

    /** Black ballpoint, fully shaded. */
    PEN,

    /** Very light pencil pressure. */
    LIGHT,

    /** Only about half the bubble shaded. */
    PARTIAL,

    /** Shaded then erased: grey residue. */
    ERASED,

    /** A check mark instead of shading. */
    CHECK,

    /** Shaded well beyond the circle. */
    OVERFILL,
}

data class BubbleMark(val question: Int, val choice: Int, val style: MarkStyle)

class SheetSpec(
    val layout: SheetLayout,
    val marks: List<BubbleMark>,
    /** Digits shaded in the student-number grid (left-aligned), or null. */
    val studentNumber: String? = null,
    val setIndex: Int? = null,
    val qrText: String? = null,
    val idStyle: MarkStyle = MarkStyle.PENCIL,
)

/** Loads a layout exported by the app (src/test/resources/layouts). */
fun loadLayout(name: String): SheetLayout =
    SheetLayout.fromJson(File("src/test/resources/layouts/$name.json").readText())

/**
 * Draws ACEkanner sheets the way a printer and a student would, from the same
 * layout JSON the engine reads. Coordinates are page pixels at [pxPerMm] with
 * the frame offset by [marginMm].
 */
class SheetRenderer(private val pxPerMm: Double = 12.0, private val marginMm: Double = 12.0) {
    private val dictionary = Objdetect.getPredefinedDictionary(Objdetect.DICT_4X4_50)

    fun render(spec: SheetSpec, rnd: Random): Mat {
        val l = spec.layout
        val w = ((l.frameWidthMm + 2 * marginMm) * pxPerMm).roundToInt()
        val h = ((l.frameHeightMm + 2 * marginMm) * pxPerMm).roundToInt()
        val page = Mat(h, w, CvType.CV_8UC1, Scalar(246.0))
        paperTexture(page, rnd)

        // Corner markers.
        val side = (l.markerSizeMm * pxPerMm).roundToInt()
        for ((i, id) in l.markerIds.withIndex()) {
            val marker = Mat()
            dictionary.generateImageMarker(id, side, marker, 1)
            val o = toPx(l.markerOrigins[i])
            marker.copyTo(page.submat(Rect(o.x.roundToInt(), o.y.roundToInt(), side, side)))
        }

        // Header text (content near, but outside, the reading areas).
        text(page, "ACEKANNER ANSWER SHEET", PointMm(14.0, 3.0), 0.5, 120.0)
        text(page, "Midterm Examination in Programming 1", PointMm(14.0, 8.5), 0.9, 20.0, 2)
        for ((i, label) in listOf("Name", "Student no.", "Course & section", "Date").withIndex()) {
            val y = 20.0 + i * 7.5
            text(page, label, PointMm(0.0, y), 0.55, 60.0)
            Imgproc.line(page, toPx(PointMm(22.0, y + 0.8)), toPx(PointMm(90.0, y + 0.8)), Scalar(120.0), 1)
        }

        // Answer bubbles with letters, question numbers.
        val letters = listOf("A", "B", "C", "D", "E")
        for ((q, bubbles) in l.questions.withIndex()) {
            val first = bubbles[0]
            text(page, "${q + 1}", PointMm(first.x - 9.5, first.y + 1.2), 0.6, 15.0, 2)
            for ((c, b) in bubbles.withIndex()) bubble(page, b, l.bubbleRadiusMm, letters[c])
        }
        for ((col, digits) in l.idColumns.withIndex()) {
            val top = PointMm(digits[0].x - 2.2, 18.5)
            Imgproc.rectangle(page, toPx(top), toPx(PointMm(top.x + 4.4, top.y + 4.4)), Scalar(110.0), 1)
            for ((d, b) in digits.withIndex()) bubble(page, b, l.idBubbleRadiusMm, "$d")
            if (col == 0) text(page, "STUDENT NUMBER", PointMm(b0x(l), 15.5), 0.45, 60.0)
        }
        for ((i, b) in l.setBubbles.withIndex()) bubble(page, b, l.bubbleRadiusMm, letters[i])

        // QR code.
        if (spec.qrText != null) {
            val qr = Mat()
            QRCodeEncoder.create().encode(spec.qrText, qr)
            val box = l.qr
            val target = Size(box.w * pxPerMm, box.h * pxPerMm)
            val big = Mat()
            Imgproc.resize(qr, big, target, 0.0, 0.0, Imgproc.INTER_NEAREST)
            val o = toPx(PointMm(box.x, box.y))
            big.copyTo(page.submat(Rect(o.x.roundToInt(), o.y.roundToInt(), big.cols(), big.rows())))
        }

        // Student marks.
        for (m in spec.marks) mark(page, l.questions[m.question][m.choice], l.bubbleRadiusMm, m.style, rnd)
        spec.studentNumber?.forEachIndexed { col, ch ->
            mark(page, l.idColumns[col][ch - '0'], l.idBubbleRadiusMm, spec.idStyle, rnd)
        }
        spec.setIndex?.let { mark(page, l.setBubbles[it], l.bubbleRadiusMm, MarkStyle.PENCIL, rnd) }
        return page
    }

    private fun b0x(l: SheetLayout) = l.idColumns[0][0].x - 2.2

    fun toPx(p: PointMm) = Point((p.x + marginMm) * pxPerMm, (p.y + marginMm) * pxPerMm)

    private fun bubble(page: Mat, c: PointMm, rMm: Double, label: String) {
        val center = toPx(c)
        Imgproc.circle(page, center, (rMm * pxPerMm).roundToInt(), Scalar(135.0), 2, Imgproc.LINE_AA)
        val scale = 0.028 * pxPerMm * rMm
        val sz = Imgproc.getTextSize(label, Imgproc.FONT_HERSHEY_SIMPLEX, scale, 1, IntArray(1))
        Imgproc.putText(
            page, label, Point(center.x - sz.width / 2, center.y + sz.height / 2),
            Imgproc.FONT_HERSHEY_SIMPLEX, scale, Scalar(160.0), 1, Imgproc.LINE_AA,
        )
    }

    private fun text(page: Mat, s: String, at: PointMm, scale: Double, grey: Double, thickness: Int = 1) {
        Imgproc.putText(page, s, toPx(at), Imgproc.FONT_HERSHEY_SIMPLEX, scale * pxPerMm / 8.0, Scalar(grey), thickness, Imgproc.LINE_AA)
    }

    private fun mark(page: Mat, c: PointMm, rMm: Double, style: MarkStyle, rnd: Random) {
        val r = rMm * pxPerMm
        val jitter = 0.25 * pxPerMm
        val center = toPx(c).let { Point(it.x + rnd.nextDouble(-jitter, jitter), it.y + rnd.nextDouble(-jitter, jitter)) }
        val layer = Mat(page.size(), CvType.CV_8UC1, Scalar(0.0))
        val (grey, spread) = when (style) {
            MarkStyle.PENCIL -> 75.0 to 22.0
            MarkStyle.PEN -> 35.0 to 10.0
            MarkStyle.LIGHT -> 165.0 to 18.0
            MarkStyle.PARTIAL -> 75.0 to 22.0
            MarkStyle.ERASED -> 212.0 to 10.0
            MarkStyle.CHECK -> 60.0 to 10.0
            MarkStyle.OVERFILL -> 80.0 to 20.0
        }
        when (style) {
            MarkStyle.PARTIAL -> {
                // Lower ~half of the bubble.
                val start = rnd.nextDouble(0.0, 360.0)
                Imgproc.ellipse(layer, center, Size(r * 0.95, r * 0.95), start, 0.0, 190.0, Scalar(255.0), -1)
            }
            MarkStyle.CHECK -> {
                val pts = listOf(Point(-0.6, 0.0), Point(-0.15, 0.55), Point(0.75, -0.65))
                    .map { Point(center.x + it.x * r, center.y + it.y * r) }
                Imgproc.polylines(layer, listOf(MatOfPoint(*pts.toTypedArray())), false, Scalar(255.0), max(2, (0.35 * pxPerMm).roundToInt()))
            }
            MarkStyle.OVERFILL -> Imgproc.circle(layer, center, (r * 1.3).roundToInt(), Scalar(255.0), -1, Imgproc.LINE_AA)
            MarkStyle.ERASED -> Imgproc.circle(layer, center, (r * rnd.nextDouble(0.8, 1.05)).roundToInt(), Scalar(255.0), -1, Imgproc.LINE_AA)
            else -> Imgproc.circle(layer, center, (r * rnd.nextDouble(0.85, 1.02)).roundToInt(), Scalar(255.0), -1, Imgproc.LINE_AA)
        }
        // Ink with texture, only darkening the page where the mask is set.
        val ink = Mat(page.size(), CvType.CV_8UC1)
        Core.randn(ink, grey, spread)
        val darker = Mat()
        Core.min(page, ink, darker)
        darker.copyTo(page, layer)
        layer.release(); ink.release(); darker.release()
    }

    private fun paperTexture(page: Mat, rnd: Random) {
        val noise = Mat(page.size(), CvType.CV_8UC1)
        Core.randn(noise, 0.0, 2.0)
        Core.subtract(page, noise, page)
        noise.release()
    }
}

/** Parameters of a simulated phone photo. */
data class PhotoParams(
    val rotationDeg: Double = 0.0,
    /** Max random displacement of each page corner, as a fraction of image width (perspective tilt). */
    val tilt: Double = 0.0,
    /** Page height as a fraction of the photo height. */
    val fill: Double = 0.85,
    val blurSigma: Double = 0.6,
    val noiseSigma: Double = 2.0,
    /** Darkest side of a linear lighting gradient (1.0 = even light). */
    val lightLow: Double = 1.0,
    val shadow: Boolean = false,
    val jpegQuality: Int = 90,
    val exposure: Double = 1.0,
    val width: Int = 3000,
    val height: Int = 4000,
)

object PhotoSimulator {
    private fun jitter(rnd: Random, amount: Double) = if (amount > 0) rnd.nextDouble(-amount, amount) else 0.0

    /** Places [page] in a phone photo with the given distortions. Returns a BGR image. */
    fun photograph(page: Mat, p: PhotoParams, rnd: Random): Mat {
        val w = p.width.toDouble()
        val h = p.height.toDouble()
        val pw = page.cols().toDouble()
        val ph = page.rows().toDouble()
        val a = Math.toRadians(p.rotationDeg)
        // Scale so the rotated page's bounding box fills [fill] of the photo.
        val bw = abs(pw * cos(a)) + abs(ph * sin(a))
        val bh = abs(pw * sin(a)) + abs(ph * cos(a))
        val s = p.fill * minOf(w / bw, h / bh)
        val cx = w / 2 + rnd.nextDouble(-0.03, 0.03) * w
        val cy = h / 2 + rnd.nextDouble(-0.03, 0.03) * h
        val corners = listOf(Point(0.0, 0.0), Point(pw, 0.0), Point(pw, ph), Point(0.0, ph))
        val dst = corners.map { c ->
            val x = (c.x - pw / 2) * s
            val y = (c.y - ph / 2) * s
            Point(
                cx + x * cos(a) - y * sin(a) + jitter(rnd, p.tilt) * w,
                cy + x * sin(a) + y * cos(a) + jitter(rnd, p.tilt) * w,
            )
        }
        val m = Imgproc.getPerspectiveTransform(MatOfPoint2f(*corners.toTypedArray()), MatOfPoint2f(*dst.toTypedArray()))
        val canvas = Mat(p.height, p.width, CvType.CV_8UC1, Scalar(95.0))
        val desk = Mat(canvas.size(), CvType.CV_8UC1)
        Core.randn(desk, 0.0, 12.0)
        Core.add(canvas, desk, canvas)
        Imgproc.warpPerspective(page, canvas, m, canvas.size(), Imgproc.INTER_LINEAR, Core.BORDER_TRANSPARENT)

        // Lighting: linear gradient in a random direction, optional soft shadow.
        val f = Mat()
        canvas.convertTo(f, CvType.CV_32F, p.exposure)
        if (p.lightLow < 1.0 || p.shadow) {
            val light = Mat(canvas.size(), CvType.CV_32F)
            val dir = rnd.nextDouble(0.0, 2 * Math.PI)
            val dx = cos(dir)
            val dy = sin(dir)
            val row = FloatArray(p.width)
            val shadowCenter = rnd.nextDouble(0.3, 0.7) * h
            for (y in 0 until p.height) {
                for (x in 0 until p.width) {
                    val t = (((x / w - 0.5) * dx + (y / h - 0.5) * dy) / 1.42 + 0.5).coerceIn(0.0, 1.0)
                    var v = p.lightLow + (1.0 - p.lightLow) * t
                    if (p.shadow) {
                        val d = (y - shadowCenter) / (0.12 * h)
                        v *= 1.0 - 0.32 * Math.exp(-d * d)
                    }
                    row[x] = v.toFloat()
                }
                light.put(y, 0, row)
            }
            Core.multiply(f, light, f)
            light.release()
        }
        f.convertTo(canvas, CvType.CV_8U)
        f.release()

        if (p.blurSigma > 0) Imgproc.GaussianBlur(canvas, canvas, Size(0.0, 0.0), p.blurSigma)
        if (p.noiseSigma > 0) {
            val noise = Mat(canvas.size(), CvType.CV_16S)
            Core.randn(noise, 0.0, p.noiseSigma)
            val c16 = Mat()
            canvas.convertTo(c16, CvType.CV_16S)
            Core.add(c16, noise, c16)
            c16.convertTo(canvas, CvType.CV_8U)
            noise.release(); c16.release()
        }
        val bgr = Mat()
        Imgproc.cvtColor(canvas, bgr, Imgproc.COLOR_GRAY2BGR)
        // Warm indoor light tint.
        Core.multiply(bgr, Scalar(0.92, 0.97, 1.0), bgr)
        val buf = MatOfByte()
        Imgcodecs.imencode(".jpg", bgr, buf, MatOfInt(Imgcodecs.IMWRITE_JPEG_QUALITY, p.jpegQuality))
        val photo = Imgcodecs.imdecode(buf, Imgcodecs.IMREAD_COLOR)
        canvas.release(); bgr.release(); desk.release(); m.release(); buf.release()
        return photo
    }
}
