import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/whispers/models/live_whisper.dart';
import 'package:textin/features/whispers/models/my_whisper.dart';
import 'package:textin/features/whispers/notifier/my_whispers_notifier.dart';
import 'package:textin/features/whispers/notifier/whispers_notifier.dart';
import 'package:textin/features/whispers/presentation/pages/whispers_screen.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';

class _FakeWhispersRepository implements WhispersRepository {
  _FakeWhispersRepository(this.mine);

  final List<MyWhisper> mine;

  @override
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers() async =>
      Right(mine);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> pumpScreen(WidgetTester tester, List<MyWhisper> mine) async {
    final repository = _FakeWhispersRepository(mine);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          whispersNotifierProvider.overrideWith(
            (ref) => WhispersNotifier(repository),
          ),
          myWhispersNotifierProvider.overrideWith(
            (ref) => MyWhispersNotifier(repository),
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
}
