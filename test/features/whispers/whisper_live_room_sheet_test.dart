import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/whispers/models/whisper_media_session.dart';
import 'package:textin/features/whispers/models/whisper_room_snapshot.dart';
import 'package:textin/features/whispers/notifier/whisper_room_notifier.dart';
import 'package:textin/features/whispers/presentation/widgets/whisper_live_room_sheet.dart';
import 'package:textin/features/whispers/presentation/widgets/whisper_mini_player.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';
import 'package:textin/features/whispers/services/whisper_audio_engine.dart';

class _FakeAudio implements WhisperAudioEngine {
  final mutes = <bool>[];
  int leaves = 0;

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
  Future<void> leave() async => leaves++;
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
  ) async => const Right(
    WhisperRoomSnapshot(
      listenerCount: 2,
      listeners: [
        WhisperMember(userId: 'u2', name: 'Ben'),
        WhisperMember(userId: 'u3', name: 'Chi'),
      ],
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// The mini player animates forever, so pumpAndSettle never settles.
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  for (var t = Duration.zero; t < duration; t += _frame) {
    await tester.pump(_frame);
  }
}

const _frame = Duration(milliseconds: 100);

void main() {
  late _FakeRepository repository;
  late _FakeAudio audio;
  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

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
          home: Scaffold(
            body: Builder(
              builder: (context) => Stack(
                fit: StackFit.expand,
                children: [
                  TextButton(
                    onPressed: () => openWhisperRoom(
                      context,
                      WhisperRoomArgs(
                        whisperId: 'w1',
                        title: 'Late night talk',
                        hostName: 'Ada',
                        isHost: isHost,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: WhisperMiniPlayerHost(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the host sees the room roster and can mute', (tester) async {
    await pumpRoom(tester, isHost: true);

    expect(find.text('Late night talk'), findsOneWidget);
    expect(find.text('2 Listeners'), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);

    await tester.tap(find.text('Mute'));
    await tester.pump();

    expect(audio.mutes, [true]);
    expect(find.text('Unmute'), findsOneWidget);
  });

  testWidgets('minimizing keeps the room going in the mini player', (
    tester,
  ) async {
    await pumpRoom(tester, isHost: false);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.text('Late night talk'), findsNothing);
    expect(find.text('speaking...'), findsOneWidget);
    expect(audio.leaves, 0);
    expect(containerOf(tester).read(currentWhisperRoomProvider), isNotNull);

    await tester.tap(find.text('speaking...'));
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.text('Late night talk'), findsOneWidget);
    expect(repository.calls.where((c) => c == 'join'), hasLength(1));
  });

  testWidgets('a listener closing the mini player leaves the room', (
    tester,
  ) async {
    await pumpRoom(tester, isHost: false);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('leave'));
    expect(containerOf(tester).read(currentWhisperRoomProvider), isNull);
    expect(find.text('speaking...'), findsNothing);
  });

  testWidgets('a listener leaves from inside the room', (tester) async {
    await pumpRoom(tester, isHost: false);

    expect(find.text("You're listening"), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('leave'));
    expect(containerOf(tester).read(currentWhisperRoomProvider), isNull);
  });

  testWidgets('the host ends the whisper after confirming', (tester) async {
    await pumpRoom(tester, isHost: true);

    await tester.tap(find.text('End'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'End'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('end'));
    expect(containerOf(tester).read(currentWhisperRoomProvider), isNull);
    expect(find.text('Late night talk'), findsNothing);
  });

  testWidgets('the host steps out without a close button', (tester) async {
    await pumpRoom(tester, isHost: true);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await pumpFor(tester, const Duration(seconds: 1));

    expect(find.text('speaking...'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
