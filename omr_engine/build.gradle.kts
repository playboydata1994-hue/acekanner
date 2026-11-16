plugins {
    kotlin("jvm") version "2.4.20"
}

kotlin {
    jvmToolchain(21)
}

sourceSets {
    main {
        kotlin.srcDir("../app/android/app/src/main/kotlin/com/acekanner/app/omr/core")
    }
}

dependencies {
    // Desktop OpenCV with bundled Linux/macOS/Windows natives. Same Java API as
    // the Android build (org.opencv:opencv 4.14.0) for everything the engine uses.
    implementation("org.openpnp:opencv:4.9.0-0")
    // Built into Android; needed explicitly on the desktop JVM.
    implementation("org.json:json:20260814")
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
    maxHeapSize = "2g"
    if (project.hasProperty("calibrate")) systemProperty("acek.calibrate", "1")
    testLogging {
        events("passed", "failed", "skipped")
        showStandardStreams = true
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    }
}
