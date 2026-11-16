// Host (desktop JVM) test harness for the ACEkanner OMR engine.
//
// The engine sources live in the Android app
// (app/android/app/src/main/kotlin/com/acekanner/app/omr/core) and are compiled
// here unchanged against the desktop OpenCV build, so the recognition code is
// tested on every machine without a phone. See README.md in this folder.
rootProject.name = "acekanner-omr-engine"

pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}
