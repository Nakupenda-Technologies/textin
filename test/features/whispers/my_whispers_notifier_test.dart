import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/whispers/models/my_whisper.dart';
import 'package:textin/features/whispers/notifier/my_whispers_notifier.dart';
import 'package:textin/features/whispers/notifier/whispers_notifier.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';

const _draft = MyWhisper(
  id: 'w1',
  title: 'Late night talk',
  status: WhisperStatus.draft,
);

class _FakeWhispersRepository implements WhispersRepository {
  List<MyWhisper> mine = [];
  Either<Failure, String> createResult = const Right('w1');

  @override
  Future<Either<Failure, List<MyWhisper>>> fetchMyWhispers() async =>
      Right(mine);

  @override
  Future<Either<Failure, String>> createWhisper({
    required String title,
    required bool isPrivate,
    DateTime? scheduledAt,
  }) async {
    if (createResult.isRight()) {
      mine = [MyWhisper(id: 'w1', title: title, status: WhisperStatus.draft)];
    }
    return createResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('reads my whispers from the paginated response', () {
    final whispers = MyWhisper.listFromResponse({
      'success': true,
      'data': {
        'items': [
          {
            'id': 'w1',
            'title': 'VIP Q&A',
            'status': 'scheduled',
            'visibility': 'private',
            'scheduledAt': '2026-10-28T20:00:00.000Z',
          },
          {'id': 'w2', 'title': 'Unknown status', 'status': 'deleted'},
        ],
        'nextCursor': null,
      },
    });

    expect(whispers.first.status, WhisperStatus.scheduled);
    expect(whispers.first.isPrivate, isTrue);
    expect(
      whispers.first.scheduledAt,
      DateTime.utc(2026, 10, 28, 20).toLocal(),
    );
    expect(whispers.last.status, WhisperStatus.draft);
  });

  test('creating a whisper reloads my whispers', () async {
    final notifier = MyWhispersNotifier(_FakeWhispersRepository());
    addTearDown(notifier.dispose);

    final failure = await notifier.create(
      title: 'Late night talk',
      isPrivate: false,
    );
    await pumpEventQueue();

    expect(failure, isNull);
    expect(notifier.state.status, WhispersStatus.loaded);
    expect(notifier.state.whispers, [_draft]);
  });

  test('a failed create returns the failure', () async {
    final repository = _FakeWhispersRepository()
      ..createResult = const Left(ServerFailure('Title is required'));
    final notifier = MyWhispersNotifier(repository);
    addTearDown(notifier.dispose);

    final failure = await notifier.create(title: '', isPrivate: false);

    expect(failure?.message, 'Title is required');
    expect(notifier.state.whispers, isEmpty);
  });
}
