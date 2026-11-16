package com.acekanner.app.omr.core

import org.json.JSONObject

/**
 * Decision thresholds. Bubble scores are normalized per sheet so that 0 is
 * this sheet's empty-bubble level and 1 its typical filled-bubble level.
 *
 * - score >= [fill]: filled; score <= [empty]: empty; in between: ambiguous.
 * - A question with exactly one filled bubble and one ambiguous one (typical of
 *   an incomplete erasure) is auto-resolved only when [autoResolveErasures] and
 *   the filled bubble dominates by [dominance] and the other stays at or below
 *   [erasureMax]; otherwise it is flagged for the instructor.
 */
data class OmrThresholds(
    val fill: Double,
    val empty: Double,
    val autoResolveErasures: Boolean,
    val dominance: Double,
    val erasureMax: Double,
    /** Maximum marker edge width (mm, 10-90 %): larger means out of focus. */
    val maxEdgeWidthMm: Double = 0.9,
    /** Minimum paper-minus-ink grey level difference. */
    val minContrast: Double = 60.0,
    /** Maximum fraction of the answer area washed out by glare. */
    val maxGlare: Double = 0.01,
    /** Maximum local shift (mm) needed to align any block of bubbles; more means a folded or curled sheet. */
    val maxLocalShiftMm: Double = 2.0,
) {
    companion object {
        val LENIENT = OmrThresholds(fill = 0.50, empty = 0.28, autoResolveErasures = true, dominance = 0.30, erasureMax = 0.45)
        val STANDARD = OmrThresholds(fill = 0.55, empty = 0.20, autoResolveErasures = true, dominance = 0.40, erasureMax = 0.35)
        val STRICT = OmrThresholds(fill = 0.60, empty = 0.15, autoResolveErasures = false, dominance = 1.0, erasureMax = 0.0)

        /** `lenient`, `standard`, `strict`, or a JSON object of custom values. */
        fun fromSpec(preset: String?, custom: JSONObject? = null): OmrThresholds {
            val base = when (preset) {
                "lenient" -> LENIENT
                "strict" -> STRICT
                else -> STANDARD
            }
            if (preset != "custom" || custom == null) return base
            val t = base.copy(
                fill = custom.optDouble("fill", base.fill),
                empty = custom.optDouble("empty", base.empty),
                autoResolveErasures = custom.optBoolean("autoResolveErasures", base.autoResolveErasures),
                dominance = custom.optDouble("dominance", base.dominance),
                erasureMax = custom.optDouble("erasureMax", base.erasureMax),
            )
            require(t.empty in 0.05..0.9 && t.fill in 0.1..0.95 && t.empty < t.fill) { "Invalid custom thresholds" }
            return t
        }
    }
}
