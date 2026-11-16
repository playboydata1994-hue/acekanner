package com.acekanner.app.omr.core

import org.json.JSONArray
import org.json.JSONObject

enum class MarkState(val code: String) {
    /** Exactly one clear mark. */
    ANSWERED("answered"),

    /** No mark. */
    BLANK("blank"),

    /** Two or more clear marks. */
    MULTIPLE("multiple"),

    /** Light, partial or erased marks: the instructor must decide. */
    UNCERTAIN("uncertain"),
}

/** The reading of one group of bubbles (a question, an ID column or the set row). */
class GroupReading(
    val state: MarkState,
    /** Bit i set = bubble i read as filled (or suggested, when uncertain). */
    val mask: Int,
    /** Normalized scores (0 = empty level, 1 = filled level), one per bubble. */
    val scores: DoubleArray,
    val confidence: Double,
    /** A filled answer was accepted despite a fainter (erased) second mark. */
    val erasure: Boolean = false,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("state", state.code)
        .put("mask", mask)
        .put("scores", JSONArray(scores.map { round3(it) }))
        .put("confidence", round3(confidence))
        .put("erasure", erasure)
}

enum class OmrError(val code: String, val message: String) {
    UNREADABLE_IMAGE("unreadable_image", "The photo could not be read. Please take it again."),
    NO_MARKERS("no_markers", "No answer sheet found. Fit the whole sheet, including the four black corner squares, in the frame."),
    PARTIAL_MARKERS("partial_markers", "Not all four corner squares are visible. Move back a little so the whole sheet fits."),
    WRONG_TEMPLATE("wrong_template", "This is a different answer sheet type than this examination uses."),
    TOO_BLURRY("too_blurry", "The photo is blurry. Hold the phone steady and tap to focus."),
    TOO_DARK("too_dark", "The photo is too dark or low in contrast. Move to better light."),
    GLARE("glare", "There is glare on the sheet. Tilt the sheet or phone away from the light."),
    WARPED("warped", "The sheet looks bent or folded. Flatten it on a table and try again."),
}

class OmrQuality(
    /** Marker edge width in mm (10-90 %); lower is sharper. */
    val edgeWidthMm: Double,
    val contrast: Double,
    val glareFraction: Double,
    val reprojectionMm: Double,
    val brightness: Double,
    /** Largest local alignment correction applied (mm). */
    val localShiftMm: Double = 0.0,
) {
    fun withShift(shift: Double) = OmrQuality(edgeWidthMm, contrast, glareFraction, reprojectionMm, brightness, shift)

    /** 0..1 summary for display and storage. */
    val score: Double
        get() {
            val s = (1.0 - (edgeWidthMm - 0.3) / 0.9).coerceIn(0.0, 1.0)
            val c = (contrast / 160.0).coerceIn(0.0, 1.0)
            val r = (1.0 - localShiftMm / 2.0).coerceIn(0.0, 1.0)
            return round3((s + c + r) / 3.0)
        }

    fun toJson(): JSONObject = JSONObject()
        .put("edgeWidthMm", round3(edgeWidthMm))
        .put("contrast", round3(contrast))
        .put("glare", round3(glareFraction))
        .put("reprojectionMm", round3(reprojectionMm))
        .put("brightness", round3(brightness))
        .put("localShiftMm", round3(localShiftMm))
        .put("score", score)
}

sealed class OmrOutcome {
    abstract fun toJson(): JSONObject

    class Failure(
        val error: OmrError,
        val markersFound: Int = 0,
        val detectedItemCount: Int? = null,
        val quality: OmrQuality? = null,
    ) : OmrOutcome() {
        override fun toJson(): JSONObject = JSONObject()
            .put("ok", false)
            .put("error", error.code)
            .put("message", error.message)
            .put("markersFound", markersFound)
            .put("detectedItemCount", detectedItemCount ?: JSONObject.NULL)
            .put("quality", quality?.toJson() ?: JSONObject.NULL)
    }

    class Success(
        val template: String,
        val questions: List<GroupReading>,
        val idColumns: List<GroupReading>,
        /** Digits read from the grid; '?' = unclear column; trailing blank columns dropped. */
        val studentNumber: String,
        /** True when every used column was read clearly with no gaps. */
        val studentNumberClear: Boolean,
        val set: GroupReading?,
        val qrText: String?,
        val quality: OmrQuality,
        val emptyLevel: Double,
        val filledLevel: Double,
        /** Clockwise rotation of the sheet in the photo: 0, 90, 180 or 270. */
        val rotation: Int,
        val elapsedMs: Long,
    ) : OmrOutcome() {
        val flaggedCount: Int get() = questions.count { it.state == MarkState.UNCERTAIN }

        override fun toJson(): JSONObject = JSONObject()
            .put("ok", true)
            .put("engineVersion", OmrEngine.VERSION)
            .put("template", template)
            .put("questions", JSONArray(questions.map { it.toJson() }))
            .put("idColumns", JSONArray(idColumns.map { it.toJson() }))
            .put("studentNumber", studentNumber)
            .put("studentNumberClear", studentNumberClear)
            .put("set", set?.toJson() ?: JSONObject.NULL)
            .put("qr", qrText ?: JSONObject.NULL)
            .put("quality", quality.toJson())
            .put("calibration", JSONObject().put("empty", round3(emptyLevel)).put("filled", round3(filledLevel)))
            .put("rotation", rotation)
            .put("flagged", flaggedCount)
            .put("elapsedMs", elapsedMs)
    }
}

internal fun round3(v: Double): Double = Math.round(v * 1000.0) / 1000.0
