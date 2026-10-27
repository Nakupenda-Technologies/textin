import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/whispers/models/my_whisper.dart';
import 'package:textin/features/whispers/notifier/my_whispers_notifier.dart';
import 'package:textin/features/whispers/presentation/pages/create_whisper_screen.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';

class _FakeWhispersRepository implements WhispersRepository {
  final created = <(String, bool, DateTime?)>[];
  Either<Failure, void> createResult = const Right(null);

  @override
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers() async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  }) async {
    created.add((title, isPrivate, scheduledAt));
    return createResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeWhispersRepository repository;
  bool? popped;

  setUp(() {
    repository = _FakeWhispersRepository();
    popped = null;
  });

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myWhispersNotifierProvider.overrideWith(
            (ref) => MyWhispersNotifier(repository),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                popped = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateWhisperScreen(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('needs a title before it can be created', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Create whisper'));
    await tester.pump();

    expect(repository.created, isEmpty);
  });

  testWidgets('creates a private draft and closes', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), '  Late night talk  ');
    await tester.tap(find.text('Private'));
    await tester.pump();
    await tester.tap(find.text('Create whisper'));
    await tester.pumpAndSettle();

    expect(repository.created, [('Late night talk', true, null)]);
    expect(popped, isTrue);
  });

  testWidgets('stays open when creating fails', (tester) async {
    repository.createResult = const Left(ServerFailure('Nope'));
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), 'Late night talk');
    await tester.tap(find.text('Create whisper'));
    await tester.pumpAndSettle();

    expect(find.text('New whisper'), findsOneWidget);
    expect(popped, isNull);
  });
}
