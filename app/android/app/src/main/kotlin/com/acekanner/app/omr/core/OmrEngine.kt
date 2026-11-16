package com.acekanner.app.omr.core

import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt
import org.opencv.calib3d.Calib3d
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfDouble
import org.opencv.core.MatOfInt
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Rect
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.core.TermCriteria
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import org.opencv.objdetect.ArucoDetector
import org.opencv.objdetect.DetectorParameters
import org.opencv.objdetect.Objdetect
import org.opencv.objdetect.QRCodeDetector

/** A corner marker found in an image: ID and its 4 corners (marker TL, TR, BR, BL) in pixels. */
class DetectedMarker(val id: Int, val corners: Array<Point>) {
    val center: Point
        get() = Point(corners.sumOf { it.x } / 4.0, corners.sumOf { it.y } / 4.0)
}

/**
 * Deterministic optical mark recognition for ACEkanner answer sheets.
 *
 * Pipeline (see docs/ARCHITECTURE.md §5):
 *  1. Find the four ArUco corner markers (IDs identify the template and orientation).
 *  2. Homography from the 16 marker corners to the canonical frame (8 px/mm);
 *     reject curled or folded sheets by reprojection error.
 *  3. Warp the photo to the canonical frame; quality gate (focus, contrast, glare).
 *  4. Flat-field correction: divide by a smooth background estimate, removing
 *     shadows and uneven light.
 *  5. Score each bubble by the darkness of its inner disc.
 *  6. Calibrate empty/filled levels from this sheet's own score distribution.
 *  7. Classify each question, student-number column and the set row; anything
 *     ambiguous is reported as UNCERTAIN, never guessed.
 *  8. Decode the QR code in its known position.
 *
 * Instances are not thread-safe; use one per worker thread.
 */
class OmrEngine(private val thresholds: OmrThresholds = OmrThresholds.STANDARD) {
    companion object {
        const val VERSION = "2.0.0"

        /** Marker detection runs on images no larger than this (long side, px). */
        private const val DETECT_MAX_SIDE = 2000.0

        /**
         * When markers are missing: denoised Laplacian variance below which a
         * photo that does contain paper is reported as blurry rather than as
         * "no sheet". (Sharp sheet photos measure well above 20.)
         */
        private const val BLUR_HINT = 4.0
    }

    private val detector: ArucoDetector by lazy {
        val params = DetectorParameters()
        params.set_cornerRefinementMethod(Objdetect.CORNER_REFINE_SUBPIX)
        ArucoDetector(Objdetect.getPredefinedDictionary(Objdetect.DICT_4X4_50), params)
    }

    /** Finds ACEkanner corner markers (IDs 0-23, every sheet design) in an 8-bit grey image. */
    fun detectMarkers(gray: Mat): List<DetectedMarker> {
        val corners = ArrayList<Mat>()
        val ids = Mat()
        detector.detectMarkers(gray, corners, ids)
        val found = ArrayList<DetectedMarker>()
        for (i in 0 until ids.rows()) {
            val id = ids.get(i, 0)[0].toInt()
            val c = corners[i]
            if (id in 0..SheetLayout.MAX_MARKER_ID) {
                found.add(DetectedMarker(id, Array(4) { k -> c.get(0, k).let { Point(it[0], it[1]) } }))
            }
            c.release()
        }
        ids.release()
        // If an ID appears twice (reflections, two sheets), keep the larger one.
        return found.groupBy { it.id }.values.map { list -> list.maxByOrNull { quadArea(it.corners) }!! }
    }

    /**
     * Reads one photographed sheet. [photo] is 8-bit grey or BGR. When
     * [rectifiedPath] is given, the perspective-corrected sheet is saved there
     * (JPEG) for the review screen.
     */
    fun analyze(photo: Mat, layout: SheetLayout, rectifiedPath: String? = null): OmrOutcome {
        val started = System.nanoTime()
        if (photo.empty()) return OmrOutcome.Failure(OmrError.UNREADABLE_IMAGE)
        val gray = toGray(photo)
        try {
            return analyzeGray(gray, photo, layout, rectifiedPath, started)
        } finally {
            gray.release()
        }
    }

    private fun analyzeGray(
        gray: Mat,
        photo: Mat,
        layout: SheetLayout,
        rectifiedPath: String?,
        started: Long,
    ): OmrOutcome {
        // ---- 1. Markers (on a reduced copy for speed) ----------------------
        val longSide = max(gray.cols(), gray.rows()).toDouble()
        val scale = if (longSide > DETECT_MAX_SIDE) DETECT_MAX_SIDE / longSide else 1.0
        val small = if (scale < 1.0) {
            Mat().also { Imgproc.resize(gray, it, Size(), scale, scale, Imgproc.INTER_AREA) }
        } else {
            gray
        }
        val markers = detectMarkers(small)
        val globalBrightness = Core.mean(small).`val`[0]
        val looksBlurredSheet = markers.size < 4 && paperPresent(small) && denoisedSharpness(small) < BLUR_HINT
        if (small !== gray) small.release()

        val byGroup = markers.groupBy { it.id / 4 }
        val mine = byGroup[layout.markerGroup].orEmpty()
        if (mine.size < 4) {
            val other = byGroup.filterKeys { it != layout.markerGroup }.maxByOrNull { it.value.size }
            return when {
                other != null && other.value.size >= 3 && mine.size < 2 -> OmrOutcome.Failure(
                    if (SheetLayout.designOfGroup(other.key) < layout.design) OmrError.OLD_SHEET_DESIGN else OmrError.WRONG_TEMPLATE,
                    markersFound = mine.size,
                    detectedItemCount = SheetLayout.itemsOfGroup(other.key),
                )
                globalBrightness < 35.0 -> OmrOutcome.Failure(OmrError.TOO_DARK, mine.size)
                looksBlurredSheet -> OmrOutcome.Failure(OmrError.TOO_BLURRY, mine.size)
                mine.isEmpty() -> OmrOutcome.Failure(OmrError.NO_MARKERS, 0)
                else -> OmrOutcome.Failure(OmrError.PARTIAL_MARKERS, mine.size)
            }
        }

        // ---- 2. Homography from all 16 marker corners ----------------------
        val src = ArrayList<Point>(16)
        val dst = ArrayList<Point>(16)
        val px = layout.pxPerMm.toDouble()
        val size = layout.markerSizeMm * px
        for ((index, id) in layout.markerIds.withIndex()) {
            val m = mine.first { it.id == id }
            val o = layout.markerOrigins[index]
            val ox = o.x * px
            val oy = o.y * px
            m.corners.forEach { src.add(Point(it.x / scale, it.y / scale)) }
            dst.add(Point(ox, oy))
            dst.add(Point(ox + size, oy))
            dst.add(Point(ox + size, oy + size))
            dst.add(Point(ox, oy + size))
        }
        val srcMat = MatOfPoint2f(*src.toTypedArray())
        if (scale < 1.0) {
            val win = (2.0 / scale).roundToInt().coerceIn(3, 11).toDouble()
            Imgproc.cornerSubPix(
                gray,
                srcMat,
                Size(win, win),
                Size(-1.0, -1.0),
                TermCriteria(TermCriteria.EPS + TermCriteria.COUNT, 30, 0.01),
            )
        }
        val dstMat = MatOfPoint2f(*dst.toTypedArray())
        val homography = Calib3d.findHomography(srcMat, dstMat, 0, 0.0)
        if (homography.empty()) {
            srcMat.release(); dstMat.release()
            return OmrOutcome.Failure(OmrError.WARPED, 4)
        }
        val refined = srcMat.toArray()
        val reprojectionMm = leaveOneOutErrorMm(refined, dst.toTypedArray(), px)
        // Gross check only: extrapolating one marker from the other three is
        // noisy at phone resolutions. Finer misalignment (curl, folds, lens
        // distortion) is measured and corrected on the bubbles themselves
        // (local alignment, step 4b).
        val photoPxPerMm = mine.sumOf { m ->
            (0 until 4).sumOf { k ->
                val a = m.corners[k]
                val b = m.corners[(k + 1) % 4]
                sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))
            } / 4.0
        } / mine.size / scale / layout.markerSizeMm
        val flatnessLimitMm = max(6.0, 20.0 / photoPxPerMm)
        srcMat.release(); dstMat.release()

        val rotation = rotationOf(refined[0], refined[4])

        // ---- 3. Canonical image + quality gate ------------------------------
        val warped = Mat()
        Imgproc.warpPerspective(
            gray,
            warped,
            homography,
            Size(layout.widthPx.toDouble(), layout.heightPx.toDouble()),
            Imgproc.INTER_LINEAR,
            Core.BORDER_REPLICATE,
        )
        try {
            val answerArea = answerRegion(layout)
            val edgeWidthMm = markerEdgeWidthMm(warped, layout)
            val background = background(warped)
            try {
                val paper = median(background.submat(answerArea))
                val ink = markerInk(warped, layout)
                val contrast = paper - ink
                val glare = if (paper < 240.0) {
                    fractionAtLeast(background.submat(answerArea), max(paper + 15.0, 245.0))
                } else {
                    0.0
                }
                val quality = OmrQuality(edgeWidthMm, contrast, glare, reprojectionMm, paper)

                if (reprojectionMm > flatnessLimitMm) {
                    return OmrOutcome.Failure(OmrError.WARPED, 4, quality = quality)
                }
                if (contrast < thresholds.minContrast) {
                    return OmrOutcome.Failure(OmrError.TOO_DARK, 4, quality = quality)
                }
                if (edgeWidthMm > thresholds.maxEdgeWidthMm) {
                    return OmrOutcome.Failure(OmrError.TOO_BLURRY, 4, quality = quality)
                }
                if (glare > thresholds.maxGlare) {
                    return OmrOutcome.Failure(OmrError.GLARE, 4, quality = quality)
                }

                // ---- 4. Flat-field correction --------------------------------
                val normalized = Mat()
                Core.max(background, Scalar(1.0), background)
                Core.divide(warped, background, normalized, 255.0)
                val pixels = ByteArray(layout.widthPx * layout.heightPx)
                normalized.get(0, 0, pixels)
                val sampler = Sampler(pixels, layout.widthPx, layout.heightPx, px)

                // ---- 4b. Local alignment on the printed oval outlines ----------
                val rx = layout.bubbleRxMm
                val ry = layout.bubbleRyMm
                val alignment = LocalAlignment.estimate(sampler, layout)
                if (alignment.maxShiftMm > thresholds.maxLocalShiftMm) {
                    normalized.release()
                    return OmrOutcome.Failure(OmrError.WARPED, 4, quality = quality.withShift(alignment.maxShiftMm))
                }

                // ---- 5-7. Score, calibrate, classify -------------------------
                val raw = layout.questions.mapIndexed { qi, q ->
                    val (dx, dy) = alignment.questionOffset(qi)
                    DoubleArray(5) { sampler.darkness(PointMm(q[it].x + dx, q[it].y + dy), rx, ry) }
                }
                val all = raw.flatMap { it.asList() }.sorted()
                val emptyLevel = percentile(all, 0.40)
                val maxima = raw.map { it.max() }.filter { it >= emptyLevel + 0.20 }.sorted()
                val filledLevel = (if (maxima.size >= 3) percentile(maxima, 0.5) else emptyLevel + 0.45)
                    .coerceIn(emptyLevel + 0.20, emptyLevel + 0.90)
                val span = filledLevel - emptyLevel
                fun norm(d: Double, e: Double) = (d - e) / span

                val questions = raw.map { d -> classify(DoubleArray(d.size) { norm(d[it], emptyLevel) }) }

                val (idDx, idDy) = alignment.headerOffset
                val idRaw = layout.idColumns.map { c ->
                    DoubleArray(10) {
                        sampler.darkness(PointMm(c[it].x + idDx, c[it].y + idDy), layout.idBubbleRxMm, layout.idBubbleRyMm)
                    }
                }
                val idEmpty = percentile(idRaw.flatMap { it.asList() }.sorted(), 0.40)
                val idColumns = idRaw.map { d -> classify(DoubleArray(10) { norm(d[it], idEmpty) }) }
                val (number, clear) = studentNumber(idColumns)

                val set = if (layout.setBubbles.isEmpty()) {
                    null
                } else {
                    val d = DoubleArray(layout.setBubbles.size) {
                        sampler.darkness(PointMm(layout.setBubbles[it].x + idDx, layout.setBubbles[it].y + idDy), rx, ry)
                    }
                    classify(DoubleArray(d.size) { norm(d[it], emptyLevel) })
                }

                // ---- 8. QR code ----------------------------------------------
                val qr = decodeQr(normalized, layout)
                normalized.release()

                if (rectifiedPath != null) writeRectified(photo, homography, layout, rectifiedPath)

                return OmrOutcome.Success(
                    template = layout.template,
                    questions = questions,
                    idColumns = idColumns,
                    studentNumber = number,
                    studentNumberClear = clear,
                    set = set,
                    qrText = qr,
                    quality = quality.withShift(alignment.maxShiftMm),
                    emptyLevel = emptyLevel,
                    filledLevel = filledLevel,
                    rotation = rotation,
                    elapsedMs = (System.nanoTime() - started) / 1_000_000,
                )
            } finally {
                background.release()
            }
        } finally {
            warped.release()
            homography.release()
        }
    }

    /** Decides one group of bubbles from normalized scores. */
    internal fun classify(s: DoubleArray): GroupReading {
        val t = thresholds
        val order = s.indices.sortedByDescending { s[it] }
        val top = s[order[0]]
        val second = if (order.size > 1) s[order[1]] else 0.0
        val filled = s.indices.filter { s[it] >= t.fill }
        val ambiguous = s.indices.filter { s[it] > t.empty && s[it] < t.fill }
        fun maskOf(ix: List<Int>) = ix.fold(0) { m, i -> m or (1 shl i) }
        fun clamp(v: Double) = v.coerceIn(0.0, 1.0)

        return when {
            filled.isEmpty() && ambiguous.isEmpty() ->
                GroupReading(MarkState.BLANK, 0, s, 0.5 + 0.5 * clamp((t.empty - top) / t.empty))
            filled.size == 1 && ambiguous.isEmpty() -> GroupReading(
                MarkState.ANSWERED,
                maskOf(filled),
                s,
                0.5 + 0.5 * min(clamp((top - t.fill) / (1.0 - t.fill)), clamp((t.empty - second) / t.empty)),
            )
            filled.size >= 2 && ambiguous.isEmpty() ->
                GroupReading(MarkState.MULTIPLE, maskOf(filled), s, 0.5 + 0.5 * clamp((t.empty - s[order[filled.size]].coerceAtLeast(0.0)) / t.empty))
            filled.size == 1 && ambiguous.size == 1 && t.autoResolveErasures &&
                top - second >= t.dominance && second <= t.erasureMax ->
                GroupReading(MarkState.ANSWERED, maskOf(filled), s, 0.55, erasure = true)
            filled.isNotEmpty() -> GroupReading(MarkState.UNCERTAIN, maskOf(filled), s, 0.25)
            else -> GroupReading(MarkState.UNCERTAIN, if (ambiguous.size == 1) maskOf(ambiguous) else 0, s, 0.2)
        }
    }

    // ------------------------------------------------------------------ helpers

    private fun toGray(photo: Mat): Mat {
        val out = Mat()
        when (photo.channels()) {
            1 -> photo.copyTo(out)
            3 -> Imgproc.cvtColor(photo, out, Imgproc.COLOR_BGR2GRAY)
            4 -> Imgproc.cvtColor(photo, out, Imgproc.COLOR_BGRA2GRAY)
            else -> throw IllegalArgumentException("Unsupported image with ${photo.channels()} channels")
        }
        if (out.depth() != CvType.CV_8U) out.convertTo(out, CvType.CV_8U)
        return out
    }

    /** Smooth paper-brightness estimate: removes marks smaller than ~7 mm. */
    private fun background(warped: Mat): Mat {
        val half = Mat()
        Imgproc.resize(warped, half, Size(), 0.5, 0.5, Imgproc.INTER_AREA)
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_ELLIPSE, Size(27.0, 27.0))
        Imgproc.morphologyEx(half, half, Imgproc.MORPH_CLOSE, kernel)
        Imgproc.GaussianBlur(half, half, Size(0.0, 0.0), 6.0)
        val bg = Mat()
        Imgproc.resize(half, bg, warped.size(), 0.0, 0.0, Imgproc.INTER_LINEAR)
        half.release(); kernel.release()
        return bg
    }

    private fun answerRegion(layout: SheetLayout): Rect {
        val px = layout.pxPerMm.toDouble()
        val pts = layout.questions.flatten()
        val margin = 3.0
        val x0 = ((pts.minOf { it.x } - margin) * px).roundToInt().coerceAtLeast(0)
        val y0 = ((pts.minOf { it.y } - margin) * px).roundToInt().coerceAtLeast(0)
        val x1 = ((pts.maxOf { it.x } + margin) * px).roundToInt().coerceAtMost(layout.widthPx)
        val y1 = ((pts.maxOf { it.y } + margin) * px).roundToInt().coerceAtMost(layout.heightPx)
        return Rect(x0, y0, x1 - x0, y1 - y0)
    }

    /** Mean grey of the black border cells at each marker's four corners. */
    private fun markerInk(warped: Mat, layout: SheetLayout): Double {
        val px = layout.pxPerMm.toDouble()
        val cell = layout.markerSizeMm / 6.0
        var sum = 0.0
        var n = 0
        for (o in layout.markerOrigins) {
            for ((cx, cy) in listOf(0 to 0, 5 to 0, 5 to 5, 0 to 5)) {
                val x = ((o.x + (cx + 0.5) * cell) * px).roundToInt()
                val y = ((o.y + (cy + 0.5) * cell) * px).roundToInt()
                val half = (cell * px / 4.0).roundToInt().coerceAtLeast(1)
                val roi = warped.submat(Rect(x - half, y - half, 2 * half, 2 * half))
                sum += Core.mean(roi).`val`[0]
                roi.release()
                n++
            }
        }
        return sum / n
    }

    /**
     * Focus measure: average 10–90 % width (mm) of the black/white transition
     * along the outer edges of the four corner markers. About 0.2–0.4 mm when
     * sharp; grows with defocus and motion blur. Independent of sensor noise.
     */
    private fun markerEdgeWidthMm(warped: Mat, layout: SheetLayout): Double {
        val px = layout.pxPerMm.toDouble()
        val size = layout.markerSizeMm
        val reach = 1.2 // mm on each side of the edge
        val n = (2 * reach * px).roundToInt()
        val widths = ArrayList<Double>()
        val profile = DoubleArray(n)
        val buf = ByteArray(1)
        fun sample(x: Double, y: Double): Double {
            val xi = x.roundToInt().coerceIn(0, layout.widthPx - 1)
            val yi = y.roundToInt().coerceIn(0, layout.heightPx - 1)
            warped.get(yi, xi, buf)
            return (buf[0].toInt() and 0xFF).toDouble()
        }
        for (o in layout.markerOrigins) {
            // Four outer edges: (edge point, outward normal).
            for (t in listOf(0.3, 0.5, 0.7)) {
                val edges = listOf(
                    Triple(o.x + t * size, o.y, 0.0 to -1.0),
                    Triple(o.x + t * size, o.y + size, 0.0 to 1.0),
                    Triple(o.x, o.y + t * size, -1.0 to 0.0),
                    Triple(o.x + size, o.y + t * size, 1.0 to 0.0),
                )
                for ((ex, ey, nrm) in edges) {
                    // From inside (black) to outside (paper).
                    for (i in 0 until n) {
                        val d = -reach + i / px
                        profile[i] = sample((ex + nrm.first * d) * px, (ey + nrm.second * d) * px)
                    }
                    val lo = profile.take(n / 4).average()
                    val hi = profile.takeLast(n / 4).average()
                    if (hi - lo < 40.0) continue
                    val p10 = lo + 0.1 * (hi - lo)
                    val p90 = lo + 0.9 * (hi - lo)
                    val i10 = profile.indexOfFirst { it >= p10 }
                    val i90 = profile.indexOfFirst { it >= p90 }
                    if (i10 >= 0 && i90 >= i10) widths.add((i90 - i10) / px)
                }
            }
        }
        if (widths.isEmpty()) return 99.0
        widths.sort()
        return widths[widths.size / 2]
    }

    private fun decodeQr(normalized: Mat, layout: SheetLayout): String? {
        val px = layout.pxPerMm.toDouble()
        val m = 3.0
        val q = layout.qr
        val rect = Rect(
            ((q.x - m) * px).roundToInt().coerceAtLeast(0),
            ((q.y - m) * px).roundToInt().coerceAtLeast(0),
            ((q.w + 2 * m) * px).roundToInt(),
            ((q.h + 2 * m) * px).roundToInt(),
        ).intersect(layout.widthPx, layout.heightPx)
        val crop = normalized.submat(rect)
        val detector = QRCodeDetector()
        try {
            val direct = detector.detectAndDecode(crop)
            if (!direct.isNullOrEmpty()) return direct
            val big = Mat()
            Imgproc.resize(crop, big, Size(), 2.0, 2.0, Imgproc.INTER_CUBIC)
            val second = detector.detectAndDecode(big)
            big.release()
            return second?.takeIf { it.isNotEmpty() }
        } catch (e: Exception) {
            return null
        } finally {
            crop.release()
        }
    }

    private fun writeRectified(photo: Mat, homography: Mat, layout: SheetLayout, path: String) {
        val out = Mat()
        Imgproc.warpPerspective(
            photo,
            out,
            homography,
            Size(layout.widthPx.toDouble(), layout.heightPx.toDouble()),
            Imgproc.INTER_AREA,
            Core.BORDER_REPLICATE,
        )
        Imgcodecs.imwrite(path, out, MatOfInt(Imgcodecs.IMWRITE_JPEG_QUALITY, 88))
        out.release()
    }

    private fun studentNumber(columns: List<GroupReading>): Pair<String, Boolean> {
        val chars = columns.map {
            when (it.state) {
                MarkState.ANSWERED -> ('0' + Integer.numberOfTrailingZeros(it.mask))
                MarkState.BLANK -> ' '
                else -> '?'
            }
        }
        val text = String(chars.toCharArray()).trim().replace(' ', '?')
        return text to (text.isNotEmpty() && !text.contains('?'))
    }

}

/** Reads darkness from the normalized canonical image (paper = 0, black = 1). */
internal class Sampler(val pixels: ByteArray, val width: Int, val height: Int, val pxPerMm: Double) {
    /** 1 - mean brightness of the oval's inner area (half-axes [rxMm], [ryMm]). */
    fun darkness(center: PointMm, rxMm: Double, ryMm: Double): Double {
        val cx = center.x * pxPerMm
        val cy = center.y * pxPerMm
        val rx = rxMm * INNER_FRACTION * pxPerMm
        val ry = ryMm * INNER_FRACTION * pxPerMm
        val x0 = (cx - rx).toInt().coerceAtLeast(0)
        val x1 = (cx + rx).toInt().coerceAtMost(width - 1)
        val y0 = (cy - ry).toInt().coerceAtLeast(0)
        val y1 = (cy + ry).toInt().coerceAtMost(height - 1)
        var sum = 0L
        var n = 0
        for (y in y0..y1) {
            val dy = (y + 0.5 - cy) / ry
            val row = y * width
            for (x in x0..x1) {
                val dx = (x + 0.5 - cx) / rx
                if (dx * dx + dy * dy <= 1.0) {
                    sum += pixels[row + x].toInt() and 0xFF
                    n++
                }
            }
        }
        return if (n == 0) 0.0 else 1.0 - sum.toDouble() / n / 255.0
    }

    /** Darkness of a single point (mm). */
    fun at(xMm: Double, yMm: Double): Double {
        val x = (xMm * pxPerMm).toInt()
        val y = (yMm * pxPerMm).toInt()
        if (x < 0 || y < 0 || x >= width || y >= height) return 0.0
        return 1.0 - (pixels[y * width + x].toInt() and 0xFF) / 255.0
    }

    companion object {
        /** Inner area sampled for darkness, as a fraction of the oval's half-axes. */
        const val INNER_FRACTION = 0.62
    }
}

/**
 * Local alignment: for blocks of bubbles, finds the small shift (mm) at which
 * the printed oval outlines line up best with the layout. Corrects residual
 * misalignment (slight curl, lens distortion, corner noise) and exposes folds:
 * a block that has to move more than a couple of millimetres means the sheet
 * is not flat.
 */
internal class LocalAlignment private constructor(
    private val questionBlock: IntArray,
    private val blockShift: List<Pair<Double, Double>>,
    val headerOffset: Pair<Double, Double>,
) {
    val maxShiftMm: Double
        get() = (blockShift + headerOffset).maxOf { sqrt(it.first * it.first + it.second * it.second) }

    fun questionOffset(q: Int): Pair<Double, Double> = blockShift[questionBlock[q]]

    companion object {
        private const val RANGE = 2.5 // mm searched in each direction
        private const val RING = 32
        private val COS = DoubleArray(RING) { Math.cos(2 * Math.PI * it / RING) }
        private val SIN = DoubleArray(RING) { Math.sin(2 * Math.PI * it / RING) }

        fun estimate(s: Sampler, layout: SheetLayout): LocalAlignment {
            // Blocks: each answer column split into thirds (top, middle, bottom).
            val columnOf = layout.questions.map { q -> (q[0].x * 10).roundToInt() }
            val columns = columnOf.distinct().sorted()
            val rowsPerColumn = layout.questions.count { (it[0].x * 10).roundToInt() == columns[0] }
            val third = (rowsPerColumn + 2) / 3
            val blockOf = IntArray(layout.questions.size)
            val blocks = ArrayList<MutableList<PointMm>>()
            val index = HashMap<Pair<Int, Int>, Int>()
            layout.questions.forEachIndexed { q, bubbles ->
                val col = columns.indexOf(columnOf[q])
                val row = layout.questions.subList(0, q).count { (it[0].x * 10).roundToInt() == columnOf[q] }
                val key = col to (row / third)
                val b = index.getOrPut(key) { blocks.add(ArrayList()); blocks.size - 1 }
                blocks[b].addAll(bubbles)
                blockOf[q] = b
            }
            val shifts = blocks.map { best(s, it, layout.bubbleRxMm, layout.bubbleRyMm) }
            val header = best(s, layout.idColumns.flatten(), layout.idBubbleRxMm, layout.idBubbleRyMm)
            return LocalAlignment(blockOf, shifts, header)
        }

        /** Coarse-to-fine search for the shift maximizing ring contrast. */
        private fun best(s: Sampler, bubbles: List<PointMm>, rx: Double, ry: Double): Pair<Double, Double> {
            var bestX = 0.0
            var bestY = 0.0
            var bestScore = score(s, bubbles, rx, ry, 0.0, 0.0)
            var step = 0.5
            var cx = 0.0
            var cy = 0.0
            var reach = RANGE
            while (step >= 0.125) {
                var dy = -reach
                while (dy <= reach + 1e-9) {
                    var dx = -reach
                    while (dx <= reach + 1e-9) {
                        val v = score(s, bubbles, rx, ry, cx + dx, cy + dy)
                        // Prefer the smaller shift on ties (stable on blank areas).
                        if (v > bestScore + 1e-6) {
                            bestScore = v; bestX = cx + dx; bestY = cy + dy
                        }
                        dx += step
                    }
                    dy += step
                }
                cx = bestX; cy = bestY
                reach = step
                step /= 2
            }
            return bestX to bestY
        }

        /**
         * Mean of (darkness on a band across the printed outline) minus
         * (darkness on a band just outside it), on ovals grown or shrunk by
         * the given offsets. Several offsets make the peak about 1 mm wide, so
         * the 0.5 mm coarse search cannot step over it; the letter inside the
         * oval (within ~0.7 mm of its centre) is never sampled.
         */
        private fun score(s: Sampler, bubbles: List<PointMm>, rx: Double, ry: Double, dx: Double, dy: Double): Double {
            var total = 0.0
            for (b in bubbles) {
                val x = b.x + dx
                val y = b.y + dy
                var ring = 0.0
                var out = 0.0
                for (i in 0 until RING) {
                    for (d in RING_OFFSETS) ring += s.at(x + (rx + d) * COS[i], y + (ry + d) * SIN[i])
                    for (d in OUT_OFFSETS) out += s.at(x + (rx + d) * COS[i], y + (ry + d) * SIN[i])
                }
                total += ring / (RING * RING_OFFSETS.size) - out / (RING * OUT_OFFSETS.size)
            }
            return total / bubbles.size
        }

        private val RING_OFFSETS = doubleArrayOf(-0.35, -0.1, 0.15)
        private val OUT_OFFSETS = doubleArrayOf(0.7, 1.0)
    }
}

// ---------------------------------------------------------------- free helpers

/** Laplacian variance after light denoising: structure, not sensor noise. */
internal fun denoisedSharpness(img: Mat): Double {
    val smooth = Mat()
    Imgproc.GaussianBlur(img, smooth, Size(0.0, 0.0), 1.5)
    val v = laplacianVariance(smooth)
    smooth.release()
    return v
}

/** True when a large bright, paper-like area is visible (at least 15 % of the image). */
internal fun paperPresent(img: Mat): Boolean {
    val mean = Core.mean(img).`val`[0]
    return fractionAtLeast(img, (mean + 25.0).coerceAtMost(250.0)) >= 0.15
}

internal fun laplacianVariance(img: Mat): Double {
    val lap = Mat()
    Imgproc.Laplacian(img, lap, CvType.CV_64F)
    val mean = MatOfDouble()
    val std = MatOfDouble()
    Core.meanStdDev(lap, mean, std)
    val s = std.toArray()[0]
    lap.release(); mean.release(); std.release()
    return s * s
}

internal fun median(img: Mat): Double = percentileOfMat(img, 0.5)

/** Percentile of an 8-bit single-channel image via its histogram. */
internal fun percentileOfMat(img: Mat, p: Double): Double {
    val hist = IntArray(256)
    val data = ByteArray(img.cols())
    for (y in 0 until img.rows()) {
        img.get(y, 0, data)
        for (v in data) hist[v.toInt() and 0xFF]++
    }
    val target = (img.rows().toLong() * img.cols() * p).toLong()
    var acc = 0L
    for (i in 0 until 256) {
        acc += hist[i]
        if (acc > target) return i.toDouble()
    }
    return 255.0
}

internal fun fractionAtLeast(img: Mat, level: Double): Double {
    val data = ByteArray(img.cols())
    var count = 0L
    val threshold = level.roundToInt()
    for (y in 0 until img.rows()) {
        img.get(y, 0, data)
        for (v in data) if ((v.toInt() and 0xFF) >= threshold) count++
    }
    return count.toDouble() / (img.rows().toLong() * img.cols())
}

internal fun percentile(sorted: List<Double>, p: Double): Double {
    if (sorted.isEmpty()) return 0.0
    val i = (p * (sorted.size - 1)).coerceIn(0.0, (sorted.size - 1).toDouble())
    val lo = i.toInt()
    val hi = min(lo + 1, sorted.size - 1)
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (i - lo)
}

/**
 * Flatness check: for each corner marker, fit a homography to the other three
 * and measure how far its 4 corners land from where they should be. Returns
 * the worst marker's mean error in mm. A flat sheet gives a few tenths of a
 * millimetre; a folded or curled corner gives several.
 */
internal fun leaveOneOutErrorMm(src: Array<Point>, dst: Array<Point>, pxPerMm: Double): Double {
    var worst = 0.0
    for (k in 0 until 4) {
        val keep = src.indices.filter { it / 4 != k }
        val s = MatOfPoint2f(*keep.map { src[it] }.toTypedArray())
        val d = MatOfPoint2f(*keep.map { dst[it] }.toTypedArray())
        val h = Calib3d.findHomography(s, d, 0, 0.0)
        if (h.empty()) return Double.MAX_VALUE
        val held = MatOfPoint2f(*Array(4) { src[k * 4 + it] })
        val out = MatOfPoint2f()
        Core.perspectiveTransform(held, out, h)
        val pts = out.toArray()
        var sum = 0.0
        for (i in 0 until 4) {
            val e = dst[k * 4 + i]
            sum += sqrt((pts[i].x - e.x) * (pts[i].x - e.x) + (pts[i].y - e.y) * (pts[i].y - e.y))
        }
        worst = max(worst, sum / 4 / pxPerMm)
        s.release(); d.release(); h.release(); held.release(); out.release()
    }
    return worst
}

internal fun rmsDistance(a: Array<Point>, b: Array<Point>): Double {
    var sum = 0.0
    for (i in a.indices) {
        val dx = a[i].x - b[i].x
        val dy = a[i].y - b[i].y
        sum += dx * dx + dy * dy
    }
    return sqrt(sum / a.size)
}

/** Clockwise rotation (0/90/180/270) from the TL marker's TL corner to the TR marker's TL corner. */
internal fun rotationOf(tl: Point, tr: Point): Int {
    val deg = Math.toDegrees(atan2(tr.y - tl.y, tr.x - tl.x))
    return (((deg / 90.0).roundToInt() * 90) % 360 + 360) % 360
}

internal fun quadArea(p: Array<Point>): Double {
    var a = 0.0
    for (i in p.indices) {
        val j = (i + 1) % p.size
        a += p[i].x * p[j].y - p[j].x * p[i].y
    }
    return abs(a) / 2.0
}

private fun Rect.intersect(w: Int, h: Int): Rect {
    val x0 = x.coerceIn(0, w)
    val y0 = y.coerceIn(0, h)
    val x1 = (x + width).coerceIn(0, w)
    val y1 = (y + height).coerceIn(0, h)
    return Rect(x0, y0, x1 - x0, y1 - y0)
}
