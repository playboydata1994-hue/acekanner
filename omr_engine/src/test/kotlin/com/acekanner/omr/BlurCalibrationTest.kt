package com.acekanner.omr

import com.acekanner.app.omr.core.MarkState
import com.acekanner.app.omr.core.OmrEngine
import com.acekanner.app.omr.core.OmrOutcome
import com.acekanner.app.omr.core.OmrThresholds
import kotlin.random.Random
import kotlin.test.Test

/**
 * Measurement, not a pass/fail check: how sharpness relates to accuracy.
 * Used to choose OmrThresholds.minSharpness (see docs/OMR_TEST_PROTOCOL.md).
 * Run with: ./gradlew test --tests '*BlurCalibration*' -Pcalibrate
 */
class BlurCalibrationTest {
    @Test
    fun blurSweep() {
        if (System.getProperty("acek.calibrate") != "1") return
        loadOpenCv()
        val renderer = SheetRenderer()
        val engine = OmrEngine(OmrThresholds.STANDARD.copy(maxEdgeWidthMm = 99.0))
        val layout = loadLayout("ack1-100-d12-s4")
        println("CAL sigma fill edgeMm answered flagged wrong")
        for (fill in listOf(0.6, 0.85)) {
            for (sigma in listOf(0.6, 1.2, 1.8, 2.4, 3.0, 4.0, 5.0, 6.0)) {
                repeat(2) { k ->
                    val rnd = Random((sigma * 100).toInt() * 10 + k + (fill * 1000).toInt())
                    val marks = (0 until layout.itemCount).map { BubbleMark(it, rnd.nextInt(5), if (it % 4 == 0) MarkStyle.PARTIAL else MarkStyle.PENCIL) }
                    val page = renderer.render(SheetSpec(layout, marks, studentNumber = "202100123456", setIndex = 1), rnd)
                    val photo = PhotoSimulator.photograph(page, PhotoParams(fill = fill, blurSigma = sigma, noiseSigma = 3.0), rnd)
                    when (val r = engine.analyze(photo, layout)) {
                        is OmrOutcome.Success -> {
                            var ok = 0; var flagged = 0; var wrong = 0
                            r.questions.forEachIndexed { q, g ->
                                when {
                                    g.state == MarkState.ANSWERED && g.mask == 1 shl marks[q].choice -> ok++
                                    g.state == MarkState.UNCERTAIN -> flagged++
                                    else -> wrong++
                                }
                            }
                            println("CAL $sigma $fill ${"%.2f".format(r.quality.edgeWidthMm)} $ok $flagged $wrong")
                        }
                        is OmrOutcome.Failure -> println("CAL $sigma $fill rejected ${r.error}")
                    }
                    page.release(); photo.release()
                }
            }
        }
    }
}
