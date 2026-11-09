# flutter_twilio_commkit_android

Android implementation of [`flutter_twilio_commkit`](https://pub.dev/packages/flutter_twilio_commkit).

Built with **Kotlin + Coroutines** using the official Twilio Video and Twilio Voice Android SDKs.

## Usage

This package is automatically included when you depend on `flutter_twilio_commkit` — you do not need to add it manually.

```yaml
dependencies:
  flutter_twilio_commkit: ^0.1.2
```

## Requirements

- Android SDK 26+ (Android 8.0 Oreo)
- Kotlin 1.9+
- Google Services plugin + `google-services.json` (required for FCM push notifications)

## Native dependencies

| Library | Version |
|---|---|
| Twilio Video Android SDK | 7.7.0 |
| Twilio Voice Android SDK | 6.5.0 |
| Twilio Conversations Android SDK | 2.1.2 |
| AudioSwitch | 1.1.5 |
| Kotlin Coroutines | 1.8.0 |

## Required host-app setup

### 1. `android/app/build.gradle`

```groovy
android {
    defaultConfig {
        minSdk 26
    }
}
```

### 2. `android/app/src/main/AndroidManifest.xml`

Add the following inside `<application>`:

```xml
<!-- Incoming call full-screen activity -->
<activity
    android:name="com.twiliocommkit.android.voice.TwilioIncomingCallActivity"
    android:exported="false"
    android:launchMode="singleInstance"
    android:taskAffinity="${applicationId}.call"
    android:showWhenLocked="true"
    android:turnScreenOn="true"
    android:excludeFromRecents="true"/>

<!-- FCM service for incoming call push notifications -->
<service
    android:name="com.twiliocommkit.android.voice.TwilioFcmService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT"/>
    </intent-filter>
</service>
```

And add permissions:

```xml
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

### 3. ProGuard / R8

The `proguard-rules.pro` bundled in this package handles Twilio SDK keep rules automatically.

## Architecture

- `FlutterTwilioCommKitAndroidPlugin` — plugin entry point, method/event channel routing
- `TwilioVoiceManager` — voice call lifecycle, FCM, audio focus
- `TwilioVideoManager` — video room, track registry, AudioSwitch
- `TwilioConversationManager` — Twilio Conversations (Chat) integration
- `TwilioCallForegroundService` — foreground service for background call audio
- `TwilioEventSink` — buffered event delivery to Flutter

## License

MIT — see [LICENSE](LICENSE)
