# Twilio Video SDK ProGuard rules
-keep class com.twilio.video.** { *; }
-dontwarn com.twilio.video.**

# Twilio Voice SDK ProGuard rules
-keep class com.twilio.voice.** { *; }
-dontwarn com.twilio.voice.**

# Keep plugin entry point
-keep class com.twiliocommkit.android.** { *; }

# WebRTC — Twilio Video ships WebRTC under the renamed package tvi.webrtc
-keep class tvi.webrtc.** { *; }
-dontwarn tvi.webrtc.**
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# AudioSwitch (audio routing used by Twilio Video)
-keep class com.twilio.audioswitch.** { *; }
-dontwarn com.twilio.audioswitch.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}


# Firebase is compileOnly (only the unused voice push service needs it), so
# apps without Firebase must not fail R8 on its missing classes.
-dontwarn com.google.firebase.**
