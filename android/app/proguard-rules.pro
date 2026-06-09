
# ── Flutter core ──────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core (مرجوع إليها من Flutter لكن غير مطلوبة في APK عادي)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ── just_audio ────────────────────────────────────────────
-keep class com.ryanheise.** { *; }
-keep class androidx.media.** { *; }

# ── geolocator ────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ── permission_handler ────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ── sqflite ───────────────────────────────────────────────
-keep class com.tekartik.sqflite.** { *; }

# ── path_provider ─────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ── connectivity_plus ─────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# ── shared_preferences ────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ── Dio / OkHttp ──────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# ── General ───────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
