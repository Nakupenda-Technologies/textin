import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/whispers/models/live_whisper.dart';
import 'package:textin/features/whispers/models/my_whisper.dart';
import 'package:textin/features/whispers/models/whisper_media_session.dart';
import 'package:textin/features/whispers/notifier/my_whispers_notifier.dart';
import 'package:textin/features/whispers/notifier/whisper_room_notifier.dart';
import 'package:textin/features/whispers/notifier/whispers_notifier.dart';
import 'package:textin/features/whispers/presentation/pages/whispers_screen.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';
import 'package:textin/features/whispers/services/whisper_audio_engine.dart';

class _SilentAudio implements WhisperAudioEngine {
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
  Future<void> setMuted(bool muted) async {}

  @override
  Future<void> leave() async {}
}

class _FakeWhispersRepository implements WhispersRepository {
  _FakeWhispersRepository(this.mine, {this.live = const []});

  final List<MyWhisper> mine;
  final List<LiveWhisper> live;
  final calls = <String>[];

  @override
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers() async =>
      Right(live);

  @override
  Future<Either<Failure, void>> startWhisper(String id) async {
    calls.add('start:$id');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> joinWhisper(String id) async {
    calls.add('join:$id');
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> leaveWhisper(String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, WhisperMediaSession>> createMediaSession(
    String id,
  ) async =>
      const Right(WhisperMediaSession(roomName: 'room', accessToken: 'token'));

  @override
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers() async =>
      Right(mine);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeWhispersRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester,
    List<MyWhisper> mine, {
    List<LiveWhisper> live = const [],
  }) async {
    repository = _FakeWhispersRepository(mine, live: live);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => const AuthUser(id: 'me', firstName: 'Godwin'),
          ),
          whispersNotifierProvider.overrideWith(
            (ref) => WhispersNotifier(repository),
          ),
          myWhispersNotifierProvider.overrideWith(
            (ref) => MyWhispersNotifier(repository),
          ),
          whisperRoomNotifierProvider.overrideWith(
            (ref, args) => WhisperRoomNotifier(
              args: args,
              repository: repository,
              audio: _SilentAudio(),
            ),
          ),
        ],
        child: const MaterialApp(home: WhispersScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('lists my whispers with their status', (tester) async {
    await pumpScreen(tester, [
      const MyWhisper(
        id: 'w1',
        title: 'Late night talk',
        status: WhisperStatus.draft,
      ),
      MyWhisper(
        id: 'w2',
        title: 'VIP Q&A',
        status: WhisperStatus.scheduled,
        isPrivate: true,
        scheduledAt: DateTime(2026, 10, 28, 20),
      ),
    ]);

    await tester.tap(find.text('Mine'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Late night talk'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Scheduled · Wed, Oct 28 · 8:00 PM'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('shows an empty state without whispers', (tester) async {
    await pumpScreen(tester, []);

    await tester.tap(find.text('Mine'));
    await tester.pump();
    await tester.pump();

    expect(find.text("You haven't created a whisper yet 🎙️"), findsOneWidget);
  });

  testWidgets('the new whisper button opens the form', (tester) async {
    await pumpScreen(tester, []);

    await tester.tap(find.text('New whisper'));
    await tester.pumpAndSettle();

    expect(find.text('Create whisper'), findsOneWidget);
  });

  testWidgets('going live starts the whisper and opens the room', (
    tester,
  ) async {
    await pumpScreen(tester, [
      const MyWhisper(
        id: 'w1',
        title: 'Late night talk',
        status: WhisperStatus.draft,
      ),
    ]);
    await tester.tap(find.text('Mine'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Go live'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['start:w1']);
    expect(find.text('You are hosting'), findsOneWidget);
  });

  testWidgets('tapping a live whisper joins it as a listener', (tester) async {
    await pumpScreen(
      tester,
      [],
      live: [
        const LiveWhisper(id: 'w2', title: 'Open mic', hostDisplayName: 'Ada'),
      ],
    );

    await tester.tap(find.text('Open mic'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['join:w2']);
    expect(find.text('Hosted by Ada'), findsOneWidget);
  });

  testWidgets('paid whispers are not joined', (tester) async {
    await pumpScreen(
      tester,
      [],
      live: [
        const LiveWhisper(
          id: 'w3',
          title: 'VIP Q&A',
          hostDisplayName: 'Ada',
          chargeListeners: true,
        ),
      ],
    );

    await tester.tap(find.text('VIP Q&A'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('Hosted by Ada'), findsNothing);
  });
}
