# Flutter/Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Just Audio
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Adhan
-keep class com.bulletphysics.** { *; }

# Dio
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Shared Preferences
-keep class org.json.** { *; }

# Keep data models
-keep class com.badr.shared.models.** { *; }

# Google Play Core (required by Flutter Play Store split application)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }