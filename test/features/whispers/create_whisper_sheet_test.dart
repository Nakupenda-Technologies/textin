import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/whispers/models/my_whisper.dart';
import 'package:textin/features/whispers/models/whisper_media_session.dart';
import 'package:textin/features/whispers/models/whisper_room_snapshot.dart';
import 'package:textin/features/whispers/notifier/my_whispers_notifier.dart';
import 'package:textin/features/whispers/notifier/whisper_room_notifier.dart';
import 'package:textin/features/whispers/presentation/widgets/create_whisper_sheet.dart';
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

class _FakeRepository implements WhispersRepository {
  final calls = <String>[];

  @override
  Future<Either<Failure, String>> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  }) async {
    calls.add('create:$title:$isPrivate:${scheduledAt != null}');
    return const Right('w1');
  }

  @override
  Future<Either<Failure, void>> startWhisper(String id) async {
    calls.add('start:$id');
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers() async =>
      const Right([]);

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

  setUp(() => repository = _FakeRepository());

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => const AuthUser(id: 'me', firstName: 'Godwin'),
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
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCreateWhisperSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseVisibility(WidgetTester tester, String option) async {
    await tester.tap(find.text('Select visibility'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('start needs a title', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('Create New Whisper'), findsOneWidget);
  });

  testWidgets('start creates the whisper, goes live and opens the room', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'Late night talk');
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(repository.calls, [
      'create:Late night talk:false:false',
      'start:w1',
    ]);
    expect(find.text('Create New Whisper'), findsNothing);
    expect(find.text('Hosted by Godwin'), findsOneWidget);
  });

  testWidgets('schedule waits for a title and visibility', (tester) async {
    await pumpSheet(tester);
    final schedule = find.widgetWithText(OutlinedButton, 'Schedule');

    expect(tester.widget<OutlinedButton>(schedule).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'VIP Q&A');
    await tester.pump();
    await chooseVisibility(tester, 'Private');

    expect(tester.widget<OutlinedButton>(schedule).onPressed, isNotNull);

    await tester.tap(schedule);
    await tester.pumpAndSettle();

    expect(find.text('Save whisper for later'), findsOneWidget);
  });

  testWidgets('scheduling needs a date and time', (tester) async {
    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), 'VIP Q&A');
    await tester.pump();
    await chooseVisibility(tester, 'Public');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Schedule'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Schedule'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.text('Save whisper for later'), findsOneWidget);
  });
}
