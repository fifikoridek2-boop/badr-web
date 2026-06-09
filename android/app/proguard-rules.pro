
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# just_audio
-keep class com.ryanheise.** { *; }
-keep class androidx.media.** { *; }
-keep class android.support.v4.media.** { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# quran_library
-keep class ** extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# General
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
