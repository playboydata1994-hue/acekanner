package com.acekanner.app.omr.core

import kotlin.math.roundToInt
import org.json.JSONArray
import org.json.JSONObject

/** A point in millimetres in the sheet frame (origin: top-left marker corner, y down). */
data class PointMm(val x: Double, val y: Double)

data class RectMm(val x: Double, val y: Double, val w: Double, val h: Double)

/**
 * Sheet geometry produced by the app (lib/domain/sheet_layout.dart, toJson).
 * The engine never hard-codes positions: everything comes from here.
 */
class SheetLayout(
    val template: String,
    val itemCount: Int,
    val idDigits: Int,
    val setCount: Int,
    val frameWidthMm: Double,
    val frameHeightMm: Double,
    val pxPerMm: Int,
    val markerSizeMm: Double,
    /** Top-left, top-right, bottom-right, bottom-left. */
    val markerIds: IntArray,
    val markerOrigins: List<PointMm>,
    val qr: RectMm,
    /** Answer and set ovals: half-width and half-height (mm). */
    val bubbleRxMm: Double,
    val bubbleRyMm: Double,
    /** Student-number ovals: half-width and half-height (mm). */
    val idBubbleRxMm: Double,
    val idBubbleRyMm: Double,
    /** questions[q][choice]. */
    val questions: List<List<PointMm>>,
    /** idColumns[column][digit]. */
    val idColumns: List<List<PointMm>>,
    val setBubbles: List<PointMm>,
) {
    val widthPx: Int get() = (frameWidthMm * pxPerMm).roundToInt()
    val heightPx: Int get() = (frameHeightMm * pxPerMm).roundToInt()

    /** Template group of a marker ID (4 IDs per template). */
    val markerGroup: Int get() = markerIds[0] / 4

    /** Sheet design of this layout (1 = circles, 2 = ovals). */
    val design: Int get() = designOfGroup(markerGroup)

    companion object {
        /**
         * Marker groups: 4 IDs per template, 3 templates per sheet design.
         * Design 1 (circles): IDs 0-3 = 50 items, 4-7 = 75, 8-11 = 100.
         * Design 2 (ovals):   IDs 12-15 = 50, 16-19 = 75, 20-23 = 100.
         */
        const val MAX_MARKER_ID = 23
        private val ITEMS = intArrayOf(50, 75, 100)

        fun itemsOfGroup(group: Int): Int? = if (group in 0..MAX_MARKER_ID / 4) ITEMS[group % 3] else null

        fun designOfGroup(group: Int): Int = group / 3 + 1

        fun fromJson(text: String): SheetLayout = fromJson(JSONObject(text))

        fun fromJson(o: JSONObject): SheetLayout {
            val frame = o.getJSONObject("frame")
            val markers = o.getJSONObject("markers")
            val qr = o.getJSONObject("qr")
            val ids = markers.getJSONArray("ids")
            // Design 2 has ovals ("bubble": {rx, ry}); design 1 had circles.
            val bubble = o.optJSONObject("bubble")
            val idBubble = o.optJSONObject("idBubble")
            val r = if (bubble == null) o.getDouble("bubbleRadius") else 0.0
            val idR = if (idBubble == null) o.getDouble("idBubbleRadius") else 0.0
            return SheetLayout(
                template = o.getString("template"),
                itemCount = o.getInt("items"),
                idDigits = o.getInt("idDigits"),
                setCount = o.getInt("sets"),
                frameWidthMm = frame.getDouble("w"),
                frameHeightMm = frame.getDouble("h"),
                pxPerMm = o.getInt("pxPerMm"),
                markerSizeMm = markers.getDouble("size"),
                markerIds = IntArray(ids.length()) { ids.getInt(it) },
                markerOrigins = points(markers.getJSONArray("origins")),
                qr = RectMm(qr.getDouble("x"), qr.getDouble("y"), qr.getDouble("w"), qr.getDouble("h")),
                bubbleRxMm = bubble?.getDouble("rx") ?: r,
                bubbleRyMm = bubble?.getDouble("ry") ?: r,
                idBubbleRxMm = idBubble?.getDouble("rx") ?: idR,
                idBubbleRyMm = idBubble?.getDouble("ry") ?: idR,
                questions = groups(o.getJSONArray("questions")),
                idColumns = groups(o.getJSONArray("idColumns")),
                setBubbles = points(o.getJSONArray("setBubbles")),
            ).also { it.validate() }
        }

        private fun points(a: JSONArray): List<PointMm> = List(a.length()) {
            val p = a.getJSONArray(it)
            PointMm(p.getDouble(0), p.getDouble(1))
        }

        private fun groups(a: JSONArray): List<List<PointMm>> = List(a.length()) { points(a.getJSONArray(it)) }
    }

    private fun validate() {
        require(markerIds.size == 4 && markerOrigins.size == 4) { "Layout needs 4 markers" }
        require(markerIds.all { it / 4 == markerGroup && it <= MAX_MARKER_ID }) { "Marker IDs must belong to one template" }
        require(bubbleRxMm > 0 && bubbleRyMm > 0 && idBubbleRxMm > 0 && idBubbleRyMm > 0) { "Bad bubble size" }
        require(questions.size == itemCount && questions.all { it.size == 5 }) { "Bad question layout" }
        require(idColumns.size == idDigits && idColumns.all { it.size == 10 }) { "Bad ID layout" }
        require(setCount == 1 && setBubbles.isEmpty() || setBubbles.size == setCount) { "Bad set layout" }
    }
}
