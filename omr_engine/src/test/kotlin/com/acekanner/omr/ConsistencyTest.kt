package com.acekanner.omr

import com.acekanner.app.omr.core.MarkState
import com.acekanner.app.omr.core.OmrEngine
import com.acekanner.app.omr.core.OmrThresholds
import com.acekanner.app.omr.core.SheetLayout
import java.io.File
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import org.json.JSONObject
import org.opencv.core.Mat
import org.opencv.objdetect.Objdetect

class ConsistencyTest {
    @BeforeTest
    fun setUp() = loadOpenCv()

    /** The marker bit patterns the app prints must be OpenCV's DICT_4X4_50 markers. */
    @Test
    fun `app marker bits match the OpenCV dictionary`() {
        val dart = File("../app/lib/domain/sheet_layout.dart").readText()
        val bits = Regex("'([01]{16})', // (\\d+)").findAll(dart).associate { it.groupValues[2].toInt() to it.groupValues[1] }
        assertEquals((0..SheetLayout.MAX_MARKER_ID).toSet(), bits.keys)
        val dict = Objdetect.getPredefinedDictionary(Objdetect.DICT_4X4_50)
        for (id in 0..SheetLayout.MAX_MARKER_ID) {
            val img = Mat()
            dict.generateImageMarker(id, 6, img, 1)
            val expected = (1..4).joinToString("") { r -> (1..4).joinToString("") { c -> if (img.get(r, c)[0] > 127) "1" else "0" } }
            assertEquals(expected, bits[id], "marker $id")
        }
    }

    @Test
    fun `layout fixtures parse and validate`() {
        for (name in listOf("ack3-50-d10-s1", "ack3-75-d9-s2", "ack3-100-d12-s4")) {
            val l = loadLayout(name)
            assertEquals(l.itemCount, l.questions.size)
            assertEquals(1520, l.widthPx)
            assertEquals(2000, l.heightPx)
        }
        val broken = JSONObject(File("src/test/resources/layouts/ack3-50-d10-s1.json").readText())
        broken.getJSONObject("markers").put("ids", org.json.JSONArray(listOf(24, 25, 26, 31)))
        assertFailsWith<IllegalArgumentException> { SheetLayout.fromJson(broken) }
    }

    @Test
    fun `marker groups map to sheet design and item count`() {
        val l = loadLayout("ack3-75-d9-s2")
        assertEquals(3, l.design)
        assertEquals(2.3, l.bubbleRxMm)
        assertEquals(2.3, l.bubbleRyMm)
        assertEquals(1, SheetLayout.designOfGroup(1)) // IDs 4-7: design 1, 75 items
        assertEquals(75, SheetLayout.itemsOfGroup(1))
        assertEquals(2, SheetLayout.designOfGroup(5)) // IDs 20-23: design 2, 100 items
        assertEquals(100, SheetLayout.itemsOfGroup(5))
        assertEquals(3, SheetLayout.designOfGroup(8)) // IDs 32-35: design 3, 100 items
        assertEquals(50, SheetLayout.itemsOfGroup(6))
        assertEquals(null, SheetLayout.itemsOfGroup(9))
    }

    @Test
    fun `decision rules`() {
        val e = OmrEngine(OmrThresholds.STANDARD)
        fun read(vararg s: Double) = e.classify(s)

        read(0.0, 0.02, 0.9, 0.01, 0.0).let { assertEquals(MarkState.ANSWERED, it.state); assertEquals(4, it.mask) }
        read(0.0, 0.05, 0.1, 0.01, 0.0).let { assertEquals(MarkState.BLANK, it.state) }
        read(0.9, 0.0, 0.85, 0.0, 0.0).let { assertEquals(MarkState.MULTIPLE, it.state); assertEquals(5, it.mask) }
        // Light mark only: flagged with a suggestion.
        read(0.0, 0.4, 0.0, 0.0, 0.0).let { assertEquals(MarkState.UNCERTAIN, it.state); assertEquals(2, it.mask) }
        // Clear answer + faint erased residue: accepted (standard), flagged (strict).
        read(1.0, 0.0, 0.0, 0.28, 0.0).let { assertEquals(MarkState.ANSWERED, it.state); assertTrue(it.erasure) }
        OmrEngine(OmrThresholds.STRICT).classify(doubleArrayOf(1.0, 0.0, 0.0, 0.28, 0.0)).let {
            assertEquals(MarkState.UNCERTAIN, it.state)
        }
        // Clear answer + strong second mark (not an erasure): flagged.
        read(1.0, 0.0, 0.0, 0.5, 0.0).let { assertEquals(MarkState.UNCERTAIN, it.state) }
        // Two ambiguous marks: flagged without a suggestion.
        read(0.4, 0.0, 0.45, 0.0, 0.0).let { assertEquals(MarkState.UNCERTAIN, it.state); assertEquals(0, it.mask) }
    }

    @Test
    fun `custom thresholds are validated`() {
        val ok = OmrThresholds.fromSpec("custom", JSONObject().put("fill", 0.6).put("empty", 0.2))
        assertEquals(0.6, ok.fill)
        assertFailsWith<IllegalArgumentException> {
            OmrThresholds.fromSpec("custom", JSONObject().put("fill", 0.2).put("empty", 0.3))
        }
        assertEquals(OmrThresholds.STRICT, OmrThresholds.fromSpec("strict"))
    }
}
