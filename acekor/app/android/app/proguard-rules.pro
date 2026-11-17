# ACEKOR Calculator release shrinking rules.

# SQLCipher: the native library is loaded by Dart (package:sqlite3); keep the
# Java side intact in case the loader references it.
-keep class net.zetetic.database.** { *; }
-dontwarn net.zetetic.database.**

# flutter_local_notifications uses Gson to store scheduled notifications so
# they can be restored after a reboot.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
