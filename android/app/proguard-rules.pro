#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Maps (if used, keeping just in case)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.maps.** { *; }

# Squareup (Retrofit/OkHttp usually safe but strict deps)
-dontwarn com.squareup.okhttp.**
-dontwarn com.squareup.retrofit.**
-keep class com.squareup.okhttp.** { *; }
-keep interface com.squareup.okhttp.** { *; }

# Webview
-keep class android.webkit.** { *; }

# Standard Flutter
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.** { *; }
