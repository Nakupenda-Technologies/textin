import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/whispers/models/whisper_media_session.dart';
import 'package:textin/features/whispers/models/whisper_room_snapshot.dart';
import 'package:textin/features/whispers/notifier/whisper_room_notifier.dart';
import 'package:textin/features/whispers/presentation/pages/whisper_room_screen.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';
import 'package:textin/features/whispers/services/whisper_audio_engine.dart';

class _FakeAudio implements WhisperAudioEngine {
  final mutes = <bool>[];

  @override
  Stream<WhisperAudioEvent> get events => const Stream.empty();

  @override
  Future<bool> requestMicrophone() async => true;

  @override
  Future<void> join(
    WhisperMediaSession session, {
    required bool publish,
  }) async {}

  @override
  Future<void> setMuted(bool muted) async => mutes.add(muted);

  @override
  Future<void> leave() async {}
}

class _FakeRepository implements WhispersRepository {
  final calls = <String>[];

  @override
  Future<Either<Failure, void>> joinWhisper(String id) async {
    calls.add('join');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> leaveWhisper(String id) async {
    calls.add('leave');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> endWhisper(String id) async {
    calls.add('end');
    return const Right(null);
  }

  @override
  Future<Either<Failure, WhisperMediaSession>> createMediaSession(
    String id,
  ) async => const Right(
    WhisperMediaSession(
      roomName: 'room',
      accessToken: 'token',
      canPublishAudio: true,
    ),
  );

  @override
  Future<Either<Failure, WhisperRoomSnapshot>> fetchRoomState(
    String id,
  ) async => const Right(WhisperRoomSnapshot());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepository repository;
  late _FakeAudio audio;

  setUp(() {
    repository = _FakeRepository();
    audio = _FakeAudio();
  });

  Future<void> pumpRoom(WidgetTester tester, {required bool isHost}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          whisperRoomNotifierProvider.overrideWith(
            (ref, args) => WhisperRoomNotifier(
              args: args,
              repository: repository,
              audio: audio,
            ),
          ),
        ],
        child: MaterialApp(
          home: WhisperRoomScreen(
            args: WhisperRoomArgs(
              whisperId: 'w1',
              title: 'Late night talk',
              hostName: 'Ada',
              isHost: isHost,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the host is live and can mute', (tester) async {
    await pumpRoom(tester, isHost: true);

    expect(find.text('Live'), findsOneWidget);
    expect(find.text('You are live · tap to mute'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();

    expect(audio.mutes, [true]);
    expect(find.text('Muted · tap to speak'), findsOneWidget);
  });

  testWidgets('the host ends the whisper after confirming', (tester) async {
    await pumpRoom(tester, isHost: true);

    await tester.tap(find.text('End whisper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('end'));
    expect(find.text('This whisper has ended'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('a listener joins and can leave', (tester) async {
    await pumpRoom(tester, isHost: false);

    expect(repository.calls, contains('join'));
    expect(find.text('Hosted by Ada'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
    expect(find.text('End whisper'), findsNothing);
  });
}
