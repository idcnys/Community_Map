# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keepclassmembers class * { @com.google.firebase.firestore.* <methods>; }

# Google Sign-In / GMS
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Supabase / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Gson / serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Kotlin coroutines
-keepclassmembers class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Record (audio)
-keep class com.llf.record.** { *; }

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Play Core (deferred components - not used but referenced by Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Suppress all missing class warnings for R8
-dontwarn com.google.android.play.core.tasks.OnCompleteListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
