import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/whispers/models/live_whisper.dart';
import 'package:textin/features/whispers/notifier/whispers_notifier.dart';
import 'package:textin/features/whispers/repository/whispers_repository.dart';

class _FakeWhispersRepository implements WhispersRepository {
  _FakeWhispersRepository(this.result);

  Either<Failure, List<LiveWhisper>> result;

  @override
  Future<Either<Failure, List<LiveWhisper>>> fetchLiveWhispers() async =>
      result;
}

void main() {
  test('live whispers are read from the paginated response', () {
    final whispers = LiveWhisper.listFromResponse({
      'success': true,
      'data': {
        'items': [
          {
            'id': 'w1',
            'title': 'Late night talk',
            'hostDisplayName': 'Ada Obi',
            'hostIsVerified': true,
            'listenerCount': 12,
            'chargeListeners': false,
          },
          {'title': 'Missing id'},
        ],
        'nextCursor': null,
      },
    });

    expect(whispers, [
      const LiveWhisper(
        id: 'w1',
        title: 'Late night talk',
        hostDisplayName: 'Ada Obi',
        hostIsVerified: true,
        listenerCount: 12,
      ),
    ]);
  });

  test('a failed load keeps the error message', () async {
    final notifier = WhispersNotifier(
      _FakeWhispersRepository(const Left(ServerFailure('Offline'))),
    );
    addTearDown(notifier.dispose);

    await notifier.loadLiveWhispers();

    expect(notifier.state.status, WhispersStatus.error);
    expect(notifier.state.errorMessage, 'Offline');
  });

  test('a successful load lists the live whispers', () async {
    const whisper = LiveWhisper(
      id: 'w1',
      title: 'Late night talk',
      hostDisplayName: 'Ada Obi',
    );
    final notifier = WhispersNotifier(
      _FakeWhispersRepository(const Right([whisper])),
    );
    addTearDown(notifier.dispose);

    await notifier.loadLiveWhispers();

    expect(notifier.state.status, WhispersStatus.loaded);
    expect(notifier.state.whispers, [whisper]);
  });
}
