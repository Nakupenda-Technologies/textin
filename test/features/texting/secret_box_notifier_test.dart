import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/texting/models/conversation.dart';
import 'package:textin/features/texting/notifier/secret_box_notifier.dart';

import 'inbox_notifier_test.dart' show MockTextingRepository;

const _secretChat = Conversation(
  id: 'secret_1',
  name: 'Godwin',
  inSecretInbox: true,
);

class _SecretRepository extends MockTextingRepository {
  Either<Failure, void> toggleResult = const Right(null);
  final toggled = <(String, bool)>[];

  @override
  Future<Either<Failure, List<Conversation>>> fetchSecretChats({
    required String myUserId,
  }) async => const Right([_secretChat]);

  @override
  Future<Either<Failure, void>> toggleSecretInbox(
    String chatId,
    bool inSecretInbox,
  ) async {
    toggled.add((chatId, inSecretInbox));
    return toggleResult;
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<SecretBoxNotifier> loadedNotifier(_SecretRepository repository) async {
    final notifier = SecretBoxNotifier(repository: repository, myUserId: 'me');
    addTearDown(notifier.dispose);
    await notifier.loadSecretChats();
    return notifier;
  }

  test('moving a chat out removes it from the secret inbox', () async {
    final repository = _SecretRepository();
    final notifier = await loadedNotifier(repository);

    final moved = await notifier.moveOut('secret_1');

    expect(moved, isTrue);
    expect(repository.toggled, [('secret_1', false)]);
    expect(notifier.state.secretConversations, isEmpty);
  });

  test('a failed move keeps the chat in the secret inbox', () async {
    final repository = _SecretRepository()
      ..toggleResult = const Left(NetworkFailure());
    final notifier = await loadedNotifier(repository);

    final moved = await notifier.moveOut('secret_1');

    expect(moved, isFalse);
    expect(notifier.state.secretConversations, [_secretChat]);
  });
}
