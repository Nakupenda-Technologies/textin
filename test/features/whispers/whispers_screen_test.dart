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
import 'package:textin/features/whispers/models/whisper_room_snapshot.dart';
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
  _FakeWhispersRepository({this.mine = const [], this.live = const []});

  final List<MyWhisper> mine;
  final List<LiveWhisper> live;
  final calls = <String>[];

  @override
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers() async =>
      Right(live);

  @override
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers() async =>
      Right(mine);

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
  Future<Either<Failure, WhisperRoomSnapshot>> fetchRoomState(
    String id,
  ) async => const Right(WhisperRoomSnapshot());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _openMic = LiveWhisper(
  id: 'w2',
  hostId: 'ada',
  title: 'Open mic',
  hostDisplayName: 'Ada Obi',
  hostUsername: 'ada',
  listenerCount: 12,
);

void main() {
  late _FakeWhispersRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<MyWhisper> mine = const [],
    List<LiveWhisper> live = const [],
  }) async {
    repository = _FakeWhispersRepository(mine: mine, live: live);
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
    await tester.pump();
  }

  testWidgets('a live whisper shows its host and listeners', (tester) async {
    await pumpScreen(tester, live: [_openMic]);

    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Open mic'), findsOneWidget);
    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('@ada'), findsOneWidget);
    expect(find.text('12 Listeners'), findsOneWidget);
    expect(find.text('Join whisper'), findsOneWidget);
  });

  testWidgets('joining a live whisper opens its room as a listener', (
    tester,
  ) async {
    await pumpScreen(tester, live: [_openMic]);

    await tester.tap(find.text('Join whisper'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['join:w2']);
    expect(find.text('Hosted by Ada Obi'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
  });

  testWidgets('the host resumes their own live whisper', (tester) async {
    await pumpScreen(
      tester,
      live: [
        const LiveWhisper(
          id: 'w3',
          hostId: 'me',
          title: 'My room',
          hostDisplayName: 'Godwin',
        ),
      ],
    );

    await tester.tap(find.text('Resume Whisper'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('End'), findsOneWidget);
  });

  testWidgets('paid whispers are not joined', (tester) async {
    await pumpScreen(
      tester,
      live: [
        const LiveWhisper(
          id: 'w4',
          title: 'VIP Q&A',
          hostDisplayName: 'Ada',
          chargeListeners: true,
        ),
      ],
    );

    await tester.tap(find.text('Join whisper'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('Hosted by Ada'), findsNothing);
  });

  testWidgets('upcoming whispers can be started', (tester) async {
    await pumpScreen(
      tester,
      mine: [
        MyWhisper(
          id: 'w5',
          title: 'Friday Q&A',
          status: WhisperStatus.scheduled,
          scheduledAt: DateTime(2026, 10, 30, 20),
        ),
        const MyWhisper(
          id: 'w6',
          title: 'Old draft',
          status: WhisperStatus.draft,
        ),
      ],
    );

    expect(find.text('Your upcoming whispers'), findsOneWidget);
    expect(find.text('Oct 30, 8:00 PM'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);

    await tester.tap(find.text('Start').first);
    await tester.pumpAndSettle();

    expect(repository.calls, ['start:w5']);
    expect(find.text('End'), findsOneWidget);
  });

  testWidgets('past whispers show when they ran', (tester) async {
    await pumpScreen(
      tester,
      mine: [
        MyWhisper(
          id: 'w7',
          title: 'Late night talk',
          status: WhisperStatus.ended,
          startedAt: DateTime(2026, 10, 27, 20),
          endedAt: DateTime(2026, 10, 27, 21, 15),
        ),
      ],
    );

    expect(find.text('Your past whispers'), findsOneWidget);
    expect(find.text('Oct 27, 9:15 PM · 1 hr 15 min'), findsOneWidget);
  });

  testWidgets('searching filters the live whispers', (tester) async {
    await pumpScreen(tester, live: [_openMic]);

    await tester.enterText(find.byType(TextField), 'cooking');
    await tester.pump();

    expect(find.text('Open mic'), findsNothing);
    expect(find.text('No whispers match your search'), findsOneWidget);
  });

  testWidgets('the mic button opens the create sheet', (tester) async {
    await pumpScreen(tester);

    expect(find.text('No live whispers right now'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.mic).last);
    await tester.pumpAndSettle();

    expect(find.text('Create New Whisper'), findsOneWidget);
  });
}
