import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Create android/key.properties (never commit it) with:
//   storeFile=/absolute/path/to/acekanner-upload.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
// See docs/PLAY_RELEASE.md (Phase 9). Without it, release builds are signed
// with the debug key so they can be tested locally, and Google Play will refuse them.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.acekanner.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.acekanner.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "ACEkanner: android/key.properties not found - release build is signed " +
                        "with the DEBUG key and cannot be uploaded to Google Play.",
                )
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        jniLibs {
            // OpenCV and other native libraries both ship the shared C++ runtime.
            pickFirsts += "**/libc++_shared.so"
            // OpenCV also ships 32-bit x86 libraries. Flutter does not support that
            // ABI, so they would only add size (and a broken x86 split on Play).
            excludes += "lib/x86/**"
            // Required for 16 KB page-size devices: keep .so files uncompressed and aligned.
            useLegacyPackaging = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Encrypted SQLite (SQLCipher). Only its libsqlcipher.so is used: Dart's
    // package:sqlite3 loads it directly (see pubspec.yaml hooks).
    implementation("net.zetetic:sqlcipher-android:4.20.0")

    // Official OpenCV Android build (Maven Central), used by the OMR engine.
    implementation("org.opencv:opencv:4.14.0")
}

flutter {
    source = "../.."
}
