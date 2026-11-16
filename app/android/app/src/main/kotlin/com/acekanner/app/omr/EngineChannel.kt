package com.acekanner.app.omr

import android.os.Build
import android.os.Handler
import android.os.Looper
import com.acekanner.app.omr.core.OmrEngine
import com.acekanner.app.omr.core.OmrError
import com.acekanner.app.omr.core.OmrOutcome
import com.acekanner.app.omr.core.OmrThresholds
import com.acekanner.app.omr.core.SheetLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONArray
import org.json.JSONObject
import org.opencv.android.OpenCVLoader
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc

/**
 * Platform channel `com.acekanner.app/omr` between Flutter and the OMR engine.
 *
 * - `engineInfo`: loads OpenCV and reports its version (Settings > About).
 * - `analyzeSheet`: reads one captured photo (worker thread) and returns the
 *   engine's JSON result; also writes the perspective-corrected image.
 * - `detectMarkers`: quick marker check on a downscaled live preview frame for
 *   on-screen guidance and auto-capture. Frames arriving while the previous
 *   one is still being processed are skipped.
 *
 * No image ever leaves the device.
 */
object EngineChannel {
    const val CHANNEL = "com.acekanner.app/omr"

    private val analysisWorker: ExecutorService = Executors.newSingleThreadExecutor { r ->
        Thread(r, "acekanner-omr-analyze")
    }
    private val previewWorker: ExecutorService = Executors.newSingleThreadExecutor { r ->
        Thread(r, "acekanner-omr-preview").apply { priority = Thread.MIN_PRIORITY }
    }
    private val previewBusy = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var openCvLoaded: Boolean? = null
    @Volatile private var openCvError: String? = null

    // One engine per worker thread (engines are not thread-safe).
    private val analysisEngines = HashMap<String, OmrEngine>()
    private val previewEngine by lazy { OmrEngine() }

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "engineInfo" -> analysisWorker.execute { reply(result) { engineInfo() } }
                "analyzeSheet" -> analysisWorker.execute { reply(result) { analyzeSheet(call) } }
                "detectMarkers" -> {
                    if (!previewBusy.compareAndSet(false, true)) {
                        result.success(null) // still busy with the previous frame
                    } else {
                        previewWorker.execute {
                            try {
                                reply(result) { detectMarkers(call) }
                            } finally {
                                previewBusy.set(false)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun reply(result: MethodChannel.Result, block: () -> Any?) {
        try {
            val value = block()
            mainHandler.post { result.success(value) }
        } catch (t: Throwable) {
            mainHandler.post { result.error("omr_failed", t.javaClass.simpleName + ": " + (t.message ?: ""), null) }
        }
    }

    /** Loads OpenCV once and caches the outcome. Thread-safe. */
    @Synchronized
    fun ensureOpenCv(): Boolean {
        openCvLoaded?.let { return it }
        val loaded = try {
            OpenCVLoader.initLocal()
        } catch (t: Throwable) {
            openCvError = t.javaClass.simpleName + ": " + (t.message ?: "")
            false
        }
        if (!loaded && openCvError == null) openCvError = "OpenCV native library failed to load"
        openCvLoaded = loaded
        return loaded
    }

    private fun engineInfo(): Map<String, Any?> {
        val loaded = ensureOpenCv()
        return mapOf(
            "opencvLoaded" to loaded,
            "opencvVersion" to if (loaded) Core.VERSION else null,
            "engineVersion" to OmrEngine.VERSION,
            "error" to openCvError,
            "abi" to (Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"),
            "sdkInt" to Build.VERSION.SDK_INT,
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
        )
    }

    /** Args: imagePath, layout (JSON), preset, thresholds (JSON or null), rectifiedPath. Returns JSON text. */
    private fun analyzeSheet(call: MethodCall): String {
        check(ensureOpenCv()) { openCvError ?: "OpenCV unavailable" }
        val imagePath = call.argument<String>("imagePath")!!
        val layout = SheetLayout.fromJson(call.argument<String>("layout")!!)
        val preset = call.argument<String>("preset") ?: "standard"
        val custom = call.argument<String>("thresholds")?.let { JSONObject(it) }
        val rectifiedPath = call.argument<String>("rectifiedPath")
        val engine = synchronized(analysisEngines) {
            analysisEngines.getOrPut(preset + (custom?.toString() ?: "")) {
                OmrEngine(OmrThresholds.fromSpec(preset, custom))
            }
        }
        // IMREAD_COLOR applies the JPEG's EXIF orientation.
        val photo = Imgcodecs.imread(imagePath, Imgcodecs.IMREAD_COLOR)
        try {
            if (photo.empty()) return OmrOutcome.Failure(OmrError.UNREADABLE_IMAGE).toJson().toString()
            rectifiedPath?.let { File(it).parentFile?.mkdirs() }
            return engine.analyze(photo, layout, rectifiedPath).toJson().toString()
        } finally {
            photo.release()
        }
    }

    /**
     * Args: bytes (luminance plane), width, height, rowStride, maxSide.
     * Returns { ids: [..], groups: [6 counts, one per marker group: design 1 50/75/100,
     * design 2 50/75/100], corners: [[x,y]...] (0..1) }.
     */
    private fun detectMarkers(call: MethodCall): Map<String, Any?> {
        check(ensureOpenCv()) { openCvError ?: "OpenCV unavailable" }
        val bytes = call.argument<ByteArray>("bytes")!!
        val width = call.argument<Int>("width")!!
        val height = call.argument<Int>("height")!!
        val stride = call.argument<Int>("rowStride") ?: width
        val maxSide = (call.argument<Int>("maxSide") ?: 720).toDouble()
        val full = Mat(height, stride, CvType.CV_8UC1)
        full.put(0, 0, bytes.copyOf(minOf(bytes.size, height * stride)))
        val frame = full.submat(0, height, 0, width)
        val scale = minOf(1.0, maxSide / maxOf(width, height))
        val small = Mat()
        Imgproc.resize(frame, small, Size(), scale, scale, Imgproc.INTER_AREA)
        try {
            val markers = previewEngine.detectMarkers(small)
            val groups = IntArray(SheetLayout.MAX_MARKER_ID / 4 + 1)
            markers.forEach { groups[it.id / 4]++ }
            val corners = JSONArray()
            markers.forEach { m ->
                corners.put(JSONArray(listOf(m.center.x / small.cols(), m.center.y / small.rows())))
            }
            return mapOf(
                "ids" to markers.map { it.id },
                "groups" to groups.toList(),
                "centers" to corners.toString(),
            )
        } finally {
            small.release(); frame.release(); full.release()
        }
    }
}
