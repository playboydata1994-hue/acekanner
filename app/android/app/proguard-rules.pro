# ACEkanner release shrinking rules.

# OpenCV: Java classes are called from native code through JNI.
-keep class org.opencv.** { *; }
-dontwarn org.opencv.**

# SQLCipher: the native library is loaded by Dart (package:sqlite3); keep the
# Java side intact in case the loader references it.
-keep class net.zetetic.database.** { *; }
-dontwarn net.zetetic.database.**

# ACEkanner platform channels.
-keep class com.acekanner.app.** { *; }
