package com.acekanner.omr

import com.acekanner.app.omr.core.OmrEngine
import com.acekanner.app.omr.core.OmrError
import com.acekanner.app.omr.core.OmrOutcome
import com.acekanner.app.omr.core.PointMm
import com.acekanner.app.omr.core.SheetLayout
import kotlin.random.Random
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Point
import org.opencv.core.Rect
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc

/** Bad photos must be rejected with the reason the instructor can act on. */
class RejectionTest {
    private lateinit var renderer: SheetRenderer
    private val layout50 by lazy { loadLayout("ack3-50-d10-s1") }
    private val layout100 by lazy { loadLayout("ack3-100-d12-s4") }

    @BeforeTest
    fun setUp() {
        loadOpenCv()
        renderer = SheetRenderer()
    }

    private fun sheet(layout: SheetLayout, rnd: Random): Mat {
        val marks = (0 until layout.itemCount).map { BubbleMark(it, rnd.nextInt(5), MarkStyle.PENCIL) }
        return renderer.render(SheetSpec(layout, marks, studentNumber = "2021001234".take(layout.idDigits)), rnd)
    }

    private fun failure(photo: Mat, layout: SheetLayout = layout50): OmrOutcome.Failure {
        val outcome = OmrEngine().analyze(photo, layout)
        println("REJECT ${outcome.toJson()}")
        return assertIs<OmrOutcome.Failure>(outcome)
    }

    @Test
    fun `a photo without a sheet`() {
        val desk = Mat(4000, 3000, CvType.CV_8UC3, Scalar(90.0, 100.0, 110.0))
        org.opencv.core.Core.randn(desk, 100.0, 12.0)
        assertEquals(OmrError.NO_MARKERS, failure(desk).error)
    }

    @Test
    fun `a corner marker covered by a thumb`() {
        val rnd = Random(10)
        val page = sheet(layout50, rnd)
        val tl = renderer.toPx(PointMm(-2.0, -2.0))
        Imgproc.rectangle(page, Rect(tl.x.toInt(), tl.y.toInt(), 170, 170), Scalar(150.0), -1)
        val f = failure(PhotoSimulator.photograph(page, PhotoParams(), rnd))
        assertEquals(OmrError.PARTIAL_MARKERS, f.error)
        assertEquals(3, f.markersFound)
    }

    @Test
    fun `a sheet printed for a different item count`() {
        val rnd = Random(11)
        val photo = PhotoSimulator.photograph(sheet(layout100, rnd), PhotoParams(), rnd)
        val f = failure(photo, layout50)
        assertEquals(OmrError.WRONG_TEMPLATE, f.error)
        assertEquals(100, f.detectedItemCount)
    }

    @Test
    fun `sheets of older test designs are not misread`() {
        // Same geometry, but corner markers of design 1 (first circles, IDs 4-7)
        // or design 2 (ovals, IDs 16-19), both 75 items.
        for ((seed, ids) in listOf(19 to listOf(4, 5, 6, 7), 20 to listOf(16, 17, 18, 19))) {
            val rnd = Random(seed)
            val json = org.json.JSONObject(java.io.File("src/test/resources/layouts/ack3-75-d9-s2.json").readText())
            json.getJSONObject("markers").put("ids", org.json.JSONArray(ids))
            val old = SheetLayout.fromJson(json)
            val photo = PhotoSimulator.photograph(sheet(old, rnd), PhotoParams(), rnd)
            val f = failure(photo, loadLayout("ack3-75-d9-s2"))
            assertEquals(OmrError.OLD_SHEET_DESIGN, f.error, "markers $ids")
            assertEquals(75, f.detectedItemCount)
        }
    }

    @Test
    fun `a photo that is far too dark`() {
        val rnd = Random(12)
        val photo = PhotoSimulator.photograph(sheet(layout50, rnd), PhotoParams(exposure = 0.12), rnd)
        assertEquals(OmrError.TOO_DARK, failure(photo).error)
    }

    @Test
    fun `a badly blurred photo`() {
        val rnd = Random(13)
        val photo = PhotoSimulator.photograph(sheet(layout50, rnd), PhotoParams(blurSigma = 14.0, noiseSigma = 3.0), rnd)
        assertEquals(OmrError.TOO_BLURRY, failure(photo).error)
    }

    @Test
    fun `glare washing out part of the answers`() {
        val rnd = Random(14)
        val photo = PhotoSimulator.photograph(sheet(layout50, rnd), PhotoParams(exposure = 0.8), rnd)
        Imgproc.ellipse(photo, Point(1500.0, 2700.0), Size(380.0, 260.0), 20.0, 0.0, 360.0, Scalar(255.0, 255.0, 255.0), -1)
        Imgproc.GaussianBlur(photo, photo, Size(0.0, 0.0), 3.0)
        assertEquals(OmrError.GLARE, failure(photo).error)
    }

    /** Moves the bottom-right marker outward by (dx, dy) mm, as a dog-eared corner would. */
    private fun foldCorner(page: Mat, dxMm: Double, dyMm: Double) {
        val o = renderer.toPx(PointMm(180.0, 240.0))
        val side = 120
        val roi = page.submat(Rect(o.x.toInt(), o.y.toInt(), side, side)).clone()
        page.submat(Rect(o.x.toInt(), o.y.toInt(), side, side)).setTo(Scalar(246.0))
        roi.copyTo(page.submat(Rect(o.x.toInt() + (dxMm * 12).toInt(), o.y.toInt() + (dyMm * 12).toInt(), side, side)))
    }

    @Test
    fun `a mildly folded corner is rejected or read correctly, never misread`() {
        for ((i, res) in listOf(3000 to 4000, 1080 to 1920).withIndex()) {
            val rnd = Random(15 + i)
            val answers = IntArray(layout50.itemCount) { rnd.nextInt(5) }
            val page = renderer.render(
                SheetSpec(layout50, answers.mapIndexed { q, c -> BubbleMark(q, c, MarkStyle.PENCIL) }, studentNumber = "2021001234"),
                rnd,
            )
            foldCorner(page, 3.0, 2.5)
            val outcome = OmrEngine().analyze(PhotoSimulator.photograph(page, PhotoParams(width = res.first, height = res.second), rnd), layout50)
            println("FOLD ${res.first}x${res.second} -> ${outcome.toJson().optString("error", "read")} ${outcome.toJson().optJSONObject("quality")}")
            when (outcome) {
                is OmrOutcome.Failure -> assertEquals(OmrError.WARPED, outcome.error)
                is OmrOutcome.Success -> answers.forEachIndexed { q, c ->
                    val r = outcome.questions[q]
                    val ok = (r.state == com.acekanner.app.omr.core.MarkState.ANSWERED && r.mask == 1 shl c) ||
                        r.state == com.acekanner.app.omr.core.MarkState.UNCERTAIN
                    kotlin.test.assertTrue(ok, "folded sheet misread q${q + 1}")
                }
            }
        }
    }

    @Test
    fun `a badly folded corner is rejected`() {
        for ((i, res) in listOf(3000 to 4000, 1080 to 1920).withIndex()) {
            val rnd = Random(25 + i)
            val page = sheet(layout50, rnd)
            foldCorner(page, 6.0, 4.0)
            val f = failure(PhotoSimulator.photograph(page, PhotoParams(width = res.first, height = res.second), rnd))
            assertEquals(OmrError.WARPED, f.error)
        }
    }
}
