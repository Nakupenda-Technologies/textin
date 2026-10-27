import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/whispers/models/whisper_media_session.dart';
import 'package:textin/features/whispers/notifier/whisper_room_notifier.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';
import 'package:textin/features/whispers/services/whisper_audio_engine.dart';

class _FakeAudio implements WhisperAudioEngine {
  final controller = StreamController<WhisperAudioEvent>.broadcast(sync: true);
  bool micGranted = true;
  final joins = <bool>[];
  final mutes = <bool>[];
  int leaves = 0;

  @override
  Stream<WhisperAudioEvent> get events => controller.stream;

  @override
  Future<bool> requestMicrophone() async => micGranted;

  @override
  Future<void> join(
    WhisperMediaSession session, {
    required bool publish,
  }) async {
    joins.add(publish);
  }

  @override
  Future<void> setMuted(bool muted) async => mutes.add(muted);

  @override
  Future<void> leave() async => leaves++;
}

class _FakeRepository implements WhispersRepository {
  final calls = <String>[];
  Either<Failure, void> joinResult = const Right(null);
  Either<Failure, void> endResult = const Right(null);
  List<Either<Failure, WhisperMediaSession>> sessions = [
    const Right(
      WhisperMediaSession(
        roomName: 'room',
        accessToken: 'token',
        canPublishAudio: true,
      ),
    ),
  ];
  int _sessionCalls = 0;

  @override
  Future<Either<Failure, void>> joinWhisper(String id) async {
    calls.add('join');
    return joinResult;
  }

  @override
  Future<Either<Failure, void>> leaveWhisper(String id) async {
    calls.add('leave');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> endWhisper(String id) async {
    calls.add('end');
    return endResult;
  }

  @override
  Future<Either<Failure, WhisperMediaSession>> createMediaSession(
    String id,
  ) async {
    calls.add('session');
    return sessions[(_sessionCalls++).clamp(0, sessions.length - 1)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _listenerSession = WhisperMediaSession(
  roomName: 'room',
  accessToken: 'token',
);

WhisperRoomNotifier _notifier(
  _FakeRepository repository,
  _FakeAudio audio, {
  bool isHost = true,
}) => WhisperRoomNotifier(
  args: WhisperRoomArgs(
    whisperId: 'w1',
    title: 'Late night talk',
    hostName: 'Ada',
    isHost: isHost,
  ),
  repository: repository,
  audio: audio,
);

void main() {
  late _FakeRepository repository;
  late _FakeAudio audio;

  setUp(() {
    repository = _FakeRepository();
    audio = _FakeAudio();
  });

  test('the host connects and can speak straight away', () async {
    final notifier = _notifier(repository, audio);
    addTearDown(notifier.dispose);

    await notifier.enter();

    expect(repository.calls, ['session']);
    expect(audio.joins, [true]);
    expect(notifier.state.status, WhisperRoomStatus.connected);
    expect(notifier.state.canSpeak, isTrue);
    expect(notifier.state.isMuted, isFalse);
  });

  test('a listener joins first and listens muted', () async {
    repository.sessions = [const Right(_listenerSession)];
    final notifier = _notifier(repository, audio, isHost: false);
    addTearDown(notifier.dispose);

    await notifier.enter();

    expect(repository.calls, ['join', 'session']);
    expect(audio.joins, [false]);
    expect(notifier.state.canSpeak, isFalse);
  });

  test('a denied microphone joins listen-only and flags it', () async {
    audio.micGranted = false;
    final notifier = _notifier(repository, audio);
    addTearDown(notifier.dispose);

    await notifier.enter();

    expect(audio.joins, [false]);
    expect(notifier.state.micBlocked, isTrue);
    expect(notifier.state.canSpeak, isFalse);
  });

  test('a whisper that is no longer live shows as ended', () async {
    repository.joinResult = const Left(
      ServerFailure('Whisper is not live', statusCode: 400),
    );
    final notifier = _notifier(repository, audio, isHost: false);
    addTearDown(notifier.dispose);

    await notifier.enter();

    expect(notifier.state.status, WhisperRoomStatus.ended);
    expect(audio.joins, isEmpty);
  });

  test('muting is sent to the audio room', () async {
    final notifier = _notifier(repository, audio);
    addTearDown(notifier.dispose);
    await notifier.enter();

    await notifier.toggleMute();

    expect(audio.mutes, [true]);
    expect(notifier.state.isMuted, isTrue);
  });

  test('a dropped room reconnects after a short wait', () {
    fakeAsync((async) {
      final notifier = _notifier(repository, audio);
      notifier.enter();
      async.flushMicrotasks();

      audio.controller.add(WhisperAudioEvent.disconnected);
      expect(notifier.state.status, WhisperRoomStatus.reconnecting);

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(audio.joins, [true, true]);
      expect(notifier.state.status, WhisperRoomStatus.connected);
      notifier.dispose();
    });
  });

  test('reconnecting stops when the whisper has ended', () {
    fakeAsync((async) {
      repository.sessions = [
        repository.sessions.first,
        const Left(ServerFailure('Whisper is not live', statusCode: 400)),
      ];
      final notifier = _notifier(repository, audio);
      notifier.enter();
      async.flushMicrotasks();

      audio.controller.add(WhisperAudioEvent.disconnected);
      async.elapse(const Duration(minutes: 2));

      expect(notifier.state.status, WhisperRoomStatus.ended);
      expect(repository.calls.where((c) => c == 'session'), hasLength(2));
      notifier.dispose();
    });
  });

  test('ending the whisper leaves the audio room', () async {
    final notifier = _notifier(repository, audio);
    addTearDown(notifier.dispose);
    await notifier.enter();

    final failure = await notifier.end();

    expect(failure, isNull);
    expect(repository.calls, contains('end'));
    expect(audio.leaves, 1);
    expect(notifier.state.status, WhisperRoomStatus.ended);
  });

  test('a listener leaving the room tells the backend', () async {
    repository.sessions = [const Right(_listenerSession)];
    final notifier = _notifier(repository, audio, isHost: false);
    await notifier.enter();

    notifier.dispose();

    expect(repository.calls.last, 'leave');
    expect(audio.leaves, 1);
  });

  test('the host leaving the screen keeps the whisper live', () async {
    final notifier = _notifier(repository, audio);
    await notifier.enter();

    notifier.dispose();

    expect(repository.calls, isNot(contains('leave')));
    expect(repository.calls, isNot(contains('end')));
    expect(audio.leaves, 1);
  });
}
