import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_twilio_commkit/flutter_twilio_commkit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/whisper_media_session.dart';

enum WhisperAudioEvent { reconnecting, reconnected, disconnected }

abstract class WhisperAudioEngine {
  Stream<WhisperAudioEvent> get events;
  Future<bool> requestMicrophone();
  Future<void> join(WhisperMediaSession session, {required bool publish});
  Future<void> setMuted(bool muted);
  Future<void> leave();
}

class TwilioWhisperAudioEngine implements WhisperAudioEngine {
  static bool _sdkInitialized = false;
  static String _accessToken = '';

  final _events = StreamController<WhisperAudioEvent>.broadcast();
  StreamSubscription<VideoRoomEvent>? _roomEvents;

  @override
  Stream<WhisperAudioEvent> get events => _events.stream;

  // The backend owns the Twilio credentials and issues short-lived room
  // tokens; these placeholder SIDs only satisfy the SDK's local format check
  // and are never used for room connections.
  static Future<void> _ensureSdkInitialized() async {
    if (_sdkInitialized) return;
    await TwilioCommKit.initialize(
      config: TwilioCommKitConfig(
        credentials: const TwilioCredentials(
          accountSid: 'AC00000000000000000000000000000000',
          apiKeySid: 'SK00000000000000000000000000000000',
        ),
        accessTokenProvider: () async => _accessToken,
        videoConfig: const TwilioVideoConfig(defaultEnableVideo: false),
      ),
    );
    _sdkInitialized = true;
  }

  @override
  Future<bool> requestMicrophone() async =>
      (await Permission.microphone.request()).isGranted;

  @override
  Future<void> join(WhisperMediaSession session, {required bool publish}) async {
    _accessToken = session.accessToken;
    await _ensureSdkInitialized();
    await leave();

    final video = TwilioVideo.instance..resetSubscription();
    await video.joinRoom(
      accessToken: session.accessToken,
      roomName: session.roomName,
      enableVideo: false,
      enableAudio: publish,
    );
    _roomEvents = video.onRoomEvent.listen((event) {
      final mapped = switch (event) {
        RoomReconnectingRoomEvent() => WhisperAudioEvent.reconnecting,
        RoomReconnectedRoomEvent() => WhisperAudioEvent.reconnected,
        RoomDisconnectedRoomEvent() => WhisperAudioEvent.disconnected,
        _ => null,
      };
      if (mapped != null) _events.add(mapped);
    });
  }

  @override
  Future<void> setMuted(bool muted) =>
      TwilioVideo.instance.muteAudio(muted: muted);

  @override
  Future<void> leave() async {
    await _roomEvents?.cancel();
    _roomEvents = null;
    if (TwilioVideo.instance.currentRoom == null) return;
    try {
      await TwilioVideo.instance.disconnect();
    } catch (e) {
      debugPrint('[WhisperAudio] disconnect failed: $e');
    }
  }
}
