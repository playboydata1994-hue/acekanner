package com.acekanner.omr

import com.acekanner.app.omr.core.OmrEngine
import com.acekanner.app.omr.core.leaveOneOutErrorMm
import kotlin.random.Random
import kotlin.test.Test
import org.opencv.core.Point
import org.opencv.imgproc.Imgproc

class DiagnosticTest {
    @Test
    fun cornerDiagnostics() {
        if (System.getProperty("acek.calibrate") != "1") return
        loadOpenCv()
        val renderer = SheetRenderer()
        for (seedSheet in listOf(1, 3, 5)) {
            val rnd = Random(4 * 1000 + seedSheet)
            val layout = loadLayout(listOf("ack3-50-d10-s1", "ack3-75-d9-s2", "ack3-100-d12-s4")[seedSheet % 3])
            val marks = (0 until layout.itemCount).map { BubbleMark(it, rnd.nextInt(5), MarkStyle.PENCIL) }
            val page = renderer.render(SheetSpec(layout, marks, studentNumber = "1234"), rnd)
            val photo = PhotoSimulator.photograph(page, PhotoParams(rotationDeg = 180.0 + 5, tilt = 0.03, fill = 0.8, blurSigma = 0.7, width = 1080, height = 1920), rnd)
            val gray = org.opencv.core.Mat()
            Imgproc.cvtColor(photo, gray, Imgproc.COLOR_BGR2GRAY)
            val markers = OmrEngine().detectMarkers(gray).sortedBy { it.id }
            val px = 8.0
            val src = ArrayList<Point>(); val dst = ArrayList<Point>()
            for ((i, id) in layout.markerIds.withIndex()) {
                val m = markers.first { it.id == id }
                val o = layout.markerOrigins[i]
                m.corners.forEach { src.add(it) }
                val s = layout.markerSizeMm * px
                dst += listOf(Point(o.x * px, o.y * px), Point(o.x * px + s, o.y * px), Point(o.x * px + s, o.y * px + s), Point(o.x * px, o.y * px + s))
                val side = (0 until 4).map { k -> val a = m.corners[k]; val b = m.corners[(k + 1) % 4]; Math.hypot(a.x - b.x, a.y - b.y) }
                println("DIAG sheet=$seedSheet id=$id sides=${side.map { "%.1f".format(it) }}")
            }
            println("DIAG sheet=$seedSheet leaveOneOut=${"%.3f".format(leaveOneOutErrorMm(src.toTypedArray(), dst.toTypedArray(), px))}")
        }
    }
}
