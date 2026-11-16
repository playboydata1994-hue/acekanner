package com.acekanner.app.omr

import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.opencv.android.OpenCVLoader
import org.opencv.core.Core

/**
 * Platform channel between Flutter and the native OMR engine.
 *
 * Phase 2 exposes `engineInfo`, which loads OpenCV and reports its version so the
 * app can confirm on a real phone that the computer-vision library works.
 * The recognition methods (`detectMarkers`, `analyzeSheet`) are added in Phase 4.
 */
object EngineChannel {
    const val CHANNEL = "com.acekanner.app/omr"

    // OpenCV work never runs on the UI thread.
    private val worker: ExecutorService = Executors.newSingleThreadExecutor { r ->
        Thread(r, "acekanner-omr").apply { priority = Thread.NORM_PRIORITY }
    }
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var openCvLoaded: Boolean? = null
    @Volatile private var openCvError: String? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "engineInfo" -> worker.execute {
                    val info = engineInfo()
                    mainHandler.post { result.success(info) }
                }
                else -> result.notImplemented()
            }
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
            "error" to openCvError,
            "abi" to (Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"),
            "sdkInt" to Build.VERSION.SDK_INT,
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
        )
    }
}
