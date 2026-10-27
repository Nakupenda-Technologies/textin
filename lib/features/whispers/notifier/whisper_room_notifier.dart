import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/di/locator.dart';
import '../../../core/errors/error_message.dart';
import '../../../core/errors/failure.dart';
import '../repository/whispers_repository.dart';
import '../services/whisper_audio_engine.dart';

enum WhisperRoomStatus { joining, connected, reconnecting, failed, ended }

class WhisperRoomArgs extends Equatable {
  const WhisperRoomArgs({
    required this.whisperId,
    required this.title,
    required this.hostName,
    required this.isHost,
  });

  final String whisperId;
  final String title;
  final String hostName;
  final bool isHost;

  @override
  List<Object?> get props => [whisperId, title, hostName, isHost];
}

class WhisperRoomState extends Equatable {
  const WhisperRoomState({
    this.status = WhisperRoomStatus.joining,
    this.canSpeak = false,
    this.isMuted = true,
    this.micBlocked = false,
    this.isEnding = false,
    this.errorMessage,
  });

  final WhisperRoomStatus status;
  final bool canSpeak;
  final bool isMuted;
  final bool micBlocked;
  final bool isEnding;
  final String? errorMessage;

  WhisperRoomState copyWith({
    WhisperRoomStatus? status,
    bool? canSpeak,
    bool? isMuted,
    bool? micBlocked,
    bool? isEnding,
    String? errorMessage,
  }) => WhisperRoomState(
    status: status ?? this.status,
    canSpeak: canSpeak ?? this.canSpeak,
    isMuted: isMuted ?? this.isMuted,
    micBlocked: micBlocked ?? this.micBlocked,
    isEnding: isEnding ?? this.isEnding,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    canSpeak,
    isMuted,
    micBlocked,
    isEnding,
    errorMessage,
  ];
}

final whisperAudioEngineProvider = Provider<WhisperAudioEngine>(
  (_) => TwilioWhisperAudioEngine(),
);

final whisperRoomNotifierProvider = StateNotifierProvider.autoDispose
    .family<WhisperRoomNotifier, WhisperRoomState, WhisperRoomArgs>(
      (ref, args) => WhisperRoomNotifier(
        args: args,
        repository: locator<WhispersRepository>(),
        audio: ref.watch(whisperAudioEngineProvider),
      ),
    );

class WhisperRoomNotifier extends StateNotifier<WhisperRoomState> {
  WhisperRoomNotifier({
    required this.args,
    required this.repository,
    required this.audio,
  }) : super(const WhisperRoomState()) {
    _audioEvents = audio.events.listen(_onAudioEvent);
  }

  final WhisperRoomArgs args;
  final WhispersRepository repository;
  final WhisperAudioEngine audio;

  static const _backoff = [1, 2, 4, 8, 16, 30];

  late final StreamSubscription<WhisperAudioEvent> _audioEvents;
  Future<bool>? _connecting;
  int _generation = 0;
  bool _reconnecting = false;
  bool _finalFailure = false;

  String get _id => args.whisperId;

  Future<void> enter() async {
    if (!args.isHost) {
      final failure = (await repository.joinWhisper(
        _id,
      )).fold((f) => f, (_) => null);
      if (!mounted) return;
      if (failure != null) {
        _fail(failure);
        return;
      }
    }
    await _connect();
  }

  Future<void> retry() async {
    _generation++;
    _reconnecting = false;
    state = state.copyWith(status: WhisperRoomStatus.joining);
    await enter();
  }

  Future<void> toggleMute() async {
    if (!state.canSpeak) return;
    final muted = !state.isMuted;
    try {
      await audio.setMuted(muted);
      if (mounted) state = state.copyWith(isMuted: muted);
    } catch (_) {}
  }

  Future<Failure?> end() async {
    state = state.copyWith(isEnding: true);
    final result = await repository.endWhisper(_id);
    if (!mounted) return null;
    return result.fold(
      (failure) {
        state = state.copyWith(isEnding: false);
        return failure;
      },
      (_) {
        _generation++;
        audio.leave();
        state = state.copyWith(
          status: WhisperRoomStatus.ended,
          isEnding: false,
        );
        return null;
      },
    );
  }

  Future<bool> _connect() =>
      _connecting ??= _doConnect().whenComplete(() => _connecting = null);

  Future<bool> _doConnect() async {
    final result = await repository.createMediaSession(_id);
    if (!mounted) return false;
    final session = result.fold((failure) {
      _fail(failure);
      return null;
    }, (session) => session);
    if (session == null) return false;

    final publish = session.canPublishAudio && await audio.requestMicrophone();
    try {
      await audio.join(session, publish: publish);
    } catch (_) {
      if (mounted) _fail(null);
      return false;
    }
    if (!mounted) {
      audio.leave();
      return false;
    }
    state = state.copyWith(
      status: WhisperRoomStatus.connected,
      canSpeak: publish,
      isMuted: !publish,
      micBlocked: session.canPublishAudio && !publish,
    );
    return true;
  }

  // A 400 from join or the audio session means the whisper is no longer live.
  bool _isEnded(Failure? failure) => failure?.statusCode == 400;

  bool _isFinal(Failure? failure) {
    final code = failure?.statusCode;
    return code != null &&
        code >= 400 &&
        code < 500 &&
        code != 408 &&
        code != 429;
  }

  void _fail(Failure? failure) {
    _finalFailure = _isFinal(failure);
    state = state.copyWith(
      status: _isEnded(failure)
          ? WhisperRoomStatus.ended
          : WhisperRoomStatus.failed,
      errorMessage: failure == null
          ? "Live audio couldn't connect."
          : userMessage(failure),
    );
  }

  void _onAudioEvent(WhisperAudioEvent event) {
    if (!mounted || state.status == WhisperRoomStatus.ended) return;
    switch (event) {
      case WhisperAudioEvent.reconnecting:
        state = state.copyWith(status: WhisperRoomStatus.reconnecting);
      case WhisperAudioEvent.reconnected:
        state = state.copyWith(status: WhisperRoomStatus.connected);
      case WhisperAudioEvent.disconnected:
        _autoReconnect();
    }
  }

  Future<void> _autoReconnect() async {
    if (_reconnecting) return;
    _reconnecting = true;
    final generation = ++_generation;
    state = state.copyWith(status: WhisperRoomStatus.reconnecting);
    try {
      for (final seconds in _backoff) {
        await Future<void>.delayed(Duration(seconds: seconds));
        if (!mounted || generation != _generation) return;
        if (await _connect()) return;
        if (!mounted || generation != _generation) return;
        if (state.status == WhisperRoomStatus.ended || _finalFailure) return;
        state = state.copyWith(status: WhisperRoomStatus.reconnecting);
      }
      state = state.copyWith(
        status: WhisperRoomStatus.failed,
        errorMessage: "Live audio couldn't reconnect.",
      );
    } finally {
      if (generation == _generation) _reconnecting = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _audioEvents.cancel();
    audio.leave();
    if (!args.isHost && state.status != WhisperRoomStatus.ended) {
      repository.leaveWhisper(_id);
    }
    super.dispose();
  }
}
