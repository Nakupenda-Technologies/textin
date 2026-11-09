# flutter_twilio_commkit_ios

iOS implementation of [`flutter_twilio_commkit`](https://pub.dev/packages/flutter_twilio_commkit).

Built with **Swift** using the official Twilio Video and Twilio Voice iOS SDKs, with full **CallKit** and **PushKit** integration.

## Usage

This package is automatically included when you depend on `flutter_twilio_commkit` — you do not need to add it manually.

```yaml
dependencies:
  flutter_twilio_commkit: ^0.1.2
```

## Requirements

- iOS 14.0+
- Swift 5.9+
- Xcode 15+

## Native dependencies (CocoaPods)

| Library | Version |
|---|---|
| TwilioVideo | ~> 5.8 |
| TwilioVoice | ~> 6.10 |
| TwilioConversationsClient | ~> 2.7 |

## Required host-app setup

### 1. `ios/Podfile`

```ruby
platform :ios, '14.0'
```

### 2. `ios/Runner/Info.plist`

Add the following keys:

```xml
<!-- Microphone permission -->
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice and video calls.</string>

<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls.</string>

<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
    <string>remote-notification</string>
</array>
```

### 3. Capabilities in Xcode

Enable the following capabilities for the Runner target:
- **Background Modes** → Voice over IP, Audio, Remote notifications
- **Push Notifications**

### 4. AppDelegate setup

```swift
import flutter_twilio_commkit_ios

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        FlutterTwilioCommKitIosPlugin.shared?.didRegisterForRemoteNotifications(deviceToken: deviceToken)
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        FlutterTwilioCommKitIosPlugin.shared?.didReceiveRemoteNotification(userInfo: userInfo)
        completionHandler(.newData)
    }
}
```

## Architecture

- `FlutterTwilioCommKitIosPlugin` — plugin entry point, method/event channel routing, CallKit delegate
- `TwilioVoiceManager` — voice call lifecycle, PushKit/APNs, CallKit, AVAudioSession
- `TwilioVideoManager` — video room management, track handling
- `TwilioConversationManager` — Twilio Conversations (Chat) integration
- `TwilioEventSink` — buffered event delivery to Flutter

## License

MIT — see [LICENSE](LICENSE)
