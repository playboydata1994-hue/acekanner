package com.acekanner.omr

import com.acekanner.app.omr.core.MarkState
import com.acekanner.app.omr.core.OmrEngine
import com.acekanner.app.omr.core.OmrOutcome
import com.acekanner.app.omr.core.SheetLayout
import kotlin.random.Random
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.fail

/** Expected reading for one question. */
private sealed class Truth {
    data class One(val choice: Int) : Truth()
    data object Blank : Truth()
    data class Multiple(val mask: Int) : Truth()

    /** Light/partial/check marks: either read as [choice] or flagged; never anything else. */
    data class OneOrFlag(val choice: Int) : Truth()
}

/** Tally of outcomes over many questions. */
private class Tally {
    var questions = 0
    var correct = 0
    var flagged = 0
    var silentErrors = 0
    val errors = mutableListOf<String>()

    fun add(other: Tally) {
        questions += other.questions; correct += other.correct; flagged += other.flagged
        silentErrors += other.silentErrors; errors += other.errors
    }

    override fun toString() =
        "questions=$questions correct=$correct flagged=$flagged (${"%.2f".format(100.0 * flagged / questions.coerceAtLeast(1))}%) silentErrors=$silentErrors"
}

class EngineAccuracyTest {
    private lateinit var renderer: SheetRenderer
    private val layouts = listOf("ack2-50-d10-s1", "ack2-75-d9-s2", "ack2-100-d12-s4")

    @BeforeTest
    fun setUp() {
        loadOpenCv()
        renderer = SheetRenderer()
    }

    private fun randomSheet(
        layout: SheetLayout,
        rnd: Random,
        blankRate: Double = 0.05,
        specials: Map<MarkStyle, Double> = emptyMap(),
    ): Pair<SheetSpec, List<Truth>> {
        val marks = mutableListOf<BubbleMark>()
        val truth = mutableListOf<Truth>()
        for (q in 0 until layout.itemCount) {
            val roll = rnd.nextDouble()
            var acc = 0.0
            val special = specials.entries.firstOrNull { (_, p) -> acc += p; roll < acc }?.key
            val choice = rnd.nextInt(5)
            when {
                special == MarkStyle.ERASED -> {
                    // Erased first choice, final answer elsewhere.
                    val other = (choice + 1 + rnd.nextInt(4)) % 5
                    marks += BubbleMark(q, other, MarkStyle.ERASED)
                    marks += BubbleMark(q, choice, MarkStyle.PENCIL)
                    truth += Truth.OneOrFlag(choice)
                }
                special == MarkStyle.PEN -> {
                    // Two clear answers.
                    val other = (choice + 1 + rnd.nextInt(4)) % 5
                    marks += BubbleMark(q, choice, MarkStyle.PENCIL)
                    marks += BubbleMark(q, other, MarkStyle.PENCIL)
                    truth += Truth.Multiple((1 shl choice) or (1 shl other))
                }
                special != null -> {
                    marks += BubbleMark(q, choice, special)
                    truth += if (special == MarkStyle.OVERFILL) Truth.One(choice) else Truth.OneOrFlag(choice)
                }
                roll < acc + blankRate -> truth += Truth.Blank
                else -> {
                    marks += BubbleMark(q, choice, if (rnd.nextInt(4) == 0) MarkStyle.PEN else MarkStyle.PENCIL)
                    truth += Truth.One(choice)
                }
            }
        }
        val digits = (1..layout.idDigits).map { rnd.nextInt(10) }.joinToString("")
        val set = if (layout.setCount > 1) rnd.nextInt(layout.setCount) else null
        val spec = SheetSpec(layout, marks, studentNumber = digits, setIndex = set, qrText = "ACK2|K7M2Q9XA|${layout.itemCount}|${layout.idDigits}|${layout.setCount}|G")
        return spec to truth
    }

    private fun evaluate(result: OmrOutcome.Success, truth: List<Truth>, label: String): Tally {
        val t = Tally()
        for ((q, expected) in truth.withIndex()) {
            val r = result.questions[q]
            t.questions++
            val ok = when (expected) {
                is Truth.One -> r.state == MarkState.ANSWERED && r.mask == 1 shl expected.choice
                Truth.Blank -> r.state == MarkState.BLANK
                is Truth.Multiple -> r.state == MarkState.MULTIPLE && r.mask == expected.mask
                is Truth.OneOrFlag -> r.state == MarkState.ANSWERED && r.mask == 1 shl expected.choice
            }
            when {
                ok -> t.correct++
                r.state == MarkState.UNCERTAIN -> t.flagged++
                else -> {
                    t.silentErrors++
                    t.errors += "$label q${q + 1}: expected $expected got ${r.state} mask=${r.mask} scores=${r.scores.joinToString { "%.2f".format(it) }}"
                }
            }
        }
        return t
    }

    private fun runScenario(
        name: String,
        sheets: Int,
        seed: Int,
        photo: (Random) -> PhotoParams,
        specials: Map<MarkStyle, Double> = emptyMap(),
        checkIds: Boolean = true,
    ): Tally {
        val total = Tally()
        val engine = OmrEngine()
        var idCorrect = 0
        var idFlagged = 0
        var qrRead = 0
        var setCorrect = 0
        var setTotal = 0
        var maxMs = 0L
        repeat(sheets) { i ->
            val rnd = Random(seed * 1000 + i)
            val layout = loadLayout(layouts[i % layouts.size])
            val (spec, truth) = randomSheet(layout, rnd, specials = specials)
            val page = renderer.render(spec, rnd)
            val image = PhotoSimulator.photograph(page, photo(rnd), rnd)
            val outcome = engine.analyze(image, layout)
            page.release(); image.release()
            if (outcome !is OmrOutcome.Success) fail("$name sheet $i was rejected: ${outcome.toJson()}")
            total.add(evaluate(outcome, truth, "$name#$i"))
            maxMs = maxOf(maxMs, outcome.elapsedMs)
            if (outcome.studentNumber == spec.studentNumber) idCorrect++
            else if (!outcome.studentNumberClear) idFlagged++
            else total.errors += "$name#$i student number ${spec.studentNumber} read as ${outcome.studentNumber}"
            if (outcome.qrText == spec.qrText) qrRead++
            if (spec.setIndex != null) {
                setTotal++
                if (outcome.set?.state == MarkState.ANSWERED && outcome.set.mask == 1 shl spec.setIndex) setCorrect++
            }
        }
        println(
            "OMR[$name] sheets=$sheets $total idCorrect=$idCorrect idFlagged=$idFlagged " +
                "qr=$qrRead/$sheets set=$setCorrect/$setTotal maxMs=$maxMs",
        )
        total.errors.take(15).forEach { println("  ! $it") }
        if (checkIds) {
            assertEquals(sheets, idCorrect + idFlagged, "$name: a student number was misread")
        }
        return total
    }

    @Test
    fun `clean straight photos are read perfectly`() {
        val t = runScenario("clean", sheets = 9, seed = 1, photo = { PhotoParams(rotationDeg = it.nextDouble(-3.0, 3.0)) })
        assertEquals(0, t.silentErrors, t.errors.joinToString("\n"))
        assertEquals(0, t.flagged, "clean sheets should not need review")
    }

    @Test
    fun `hand-held phone photos - tilt, rotation, uneven light, blur, noise, JPEG`() {
        val t = runScenario("phone", sheets = 18, seed = 2, photo = { r ->
            PhotoParams(
                rotationDeg = r.nextDouble(-15.0, 15.0) + 90.0 * r.nextInt(4),
                tilt = r.nextDouble(0.0, 0.05),
                fill = r.nextDouble(0.6, 0.92),
                blurSigma = r.nextDouble(0.5, 1.6),
                noiseSigma = r.nextDouble(2.0, 5.0),
                lightLow = r.nextDouble(0.55, 1.0),
                shadow = r.nextBoolean(),
                jpegQuality = r.nextInt(70, 92),
                exposure = r.nextDouble(0.8, 1.05),
            )
        })
        assertEquals(0, t.silentErrors, t.errors.joinToString("\n"))
        assertTrue(t.flagged <= t.questions * 0.02, "flag rate too high: $t")
    }

    @Test
    fun `1080p camera frames (the app's capture resolution) are read correctly`() {
        val t = runScenario("1080p", sheets = 12, seed = 4, photo = { r ->
            PhotoParams(
                rotationDeg = r.nextDouble(-12.0, 12.0) + 180.0 * r.nextInt(2),
                tilt = r.nextDouble(0.0, 0.04),
                fill = r.nextDouble(0.7, 0.92),
                blurSigma = r.nextDouble(0.4, 1.0),
                noiseSigma = r.nextDouble(2.0, 4.0),
                lightLow = r.nextDouble(0.6, 1.0),
                shadow = r.nextBoolean(),
                jpegQuality = 88,
                width = 1080,
                height = 1920,
            )
        })
        assertEquals(0, t.silentErrors, t.errors.joinToString("\n"))
        assertTrue(t.flagged <= t.questions * 0.02, "flag rate too high: $t")
    }

    @Test
    fun `difficult marks are read correctly or flagged, never misread`() {
        val specials = mapOf(
            MarkStyle.LIGHT to 0.06,
            MarkStyle.PARTIAL to 0.06,
            MarkStyle.ERASED to 0.08,
            MarkStyle.CHECK to 0.05,
            MarkStyle.OVERFILL to 0.05,
            MarkStyle.PEN to 0.05, // two clear answers -> MULTIPLE
        )
        val t = runScenario("marks", sheets = 12, seed = 3, specials = specials, photo = { r ->
            PhotoParams(
                rotationDeg = r.nextDouble(-8.0, 8.0),
                tilt = r.nextDouble(0.0, 0.03),
                blurSigma = r.nextDouble(0.5, 1.2),
                noiseSigma = 3.0,
                lightLow = r.nextDouble(0.7, 1.0),
            )
        })
        assertEquals(0, t.silentErrors, t.errors.joinToString("\n"))
    }
}

fun loadOpenCv() {
    nu.pattern.OpenCV.loadLocally()
}
