import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/texting/models/api/chat_streak.dart';
import 'package:textin/features/texting/models/conversation.dart';
import 'package:textin/features/texting/models/following_user.dart';
import 'package:textin/features/texting/models/message.dart';
import 'package:textin/features/texting/notifier/inbox_notifier.dart';
import 'package:textin/features/texting/repository/texting_repository.dart';
import 'package:textin/features/texting/services/texting_socket_service.dart';
import 'package:textin/services/local_storage_service.dart';
import 'package:textin/services/websocket_service.dart';

class MockTextingRepository implements TextingRepository {
  @override
  Future<Either<Failure, List<Conversation>>> fetchRegularChats(
    int filterIndex, {
    required String myUserId,
  }) async {
    return Right(Conversation.mockData);
  }

  @override
  Future<Either<Failure, List<Conversation>>> fetchSecretChats({
    required String myUserId,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Message>>> fetchMessages(
    String chatId, {
    required String myUserId,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Message>> sendTextMessage(
    String chatId,
    String text, {
    String? replyToId,
    required String myUserId,
  }) async {
    return Right(
      Message(
        id: 'msg_1',
        content: text,
        type: MessageType.text,
        isMe: true,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, Message>> sendVoiceMessage(
    String chatId,
    String mediaUrl,
    int durationSec, {
    String? replyToId,
    required String myUserId,
  }) async {
    return Right(
      Message(
        id: 'msg_voice_1',
        content: '',
        type: MessageType.voice,
        isMe: true,
        timestamp: DateTime.now(),
        voiceDuration: Duration(seconds: durationSec),
        mediaUrl: mediaUrl,
      ),
    );
  }

  @override
  Future<Either<Failure, Message>> sendImageMessage(
    String chatId,
    String mediaUrl, {
    String? replyToId,
    required String myUserId,
  }) async {
    return Right(
      Message(
        id: 'msg_img_1',
        content: '',
        type: MessageType.image,
        isMe: true,
        timestamp: DateTime.now(),
        mediaUrl: mediaUrl,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> markChatRead(String chatId) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> togglePin(String chatId, bool isPinned) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> toggleSecretInbox(
    String chatId,
    bool inSecretInbox,
  ) async =>
      const Right(null);

  @override
  Future<Either<Failure, ChatStreak?>> fetchStreak(String chatId) async =>
      const Right(null);

  @override
  Future<Either<Failure, Conversation>> startOrGetChat({
    required String otherUserId,
    required String myUserId,
  }) async {
    return const Right(
      Conversation(id: 'new_chat', name: 'New Contact'),
    );
  }

  @override
  Future<Either<Failure, List<FollowingUser>>> fetchFollowingUsers(
    String username,
  ) async {
    return const Right([]);
  }
}

void main() {
  group('InboxNotifier tests', () {
    late InboxNotifier notifier;
    late MockTextingRepository repository;
    late TextingSocketService socketService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      repository = MockTextingRepository();
      socketService = TextingSocketService(WebSocketService());
      notifier = InboxNotifier(
        repository: repository,
        socketService: socketService,
        myUserId: 'me',
      );
    });

    tearDown(() {
      notifier.dispose();
    });

    test('initial state is correct', () {
      expect(notifier.state.status, InboxStatus.initial);
      expect(notifier.state.conversations, isEmpty);
      expect(notifier.state.selectedFilterIndex, 0);
    });

    test('loadConversations populates conversations', () async {
      await notifier.loadConversations();
      expect(notifier.state.status, InboxStatus.loaded);
      expect(notifier.state.conversations, isNotEmpty);
      expect(notifier.state.displayedConversations, isNotEmpty);
    });

    test('filter and search updates state properly', () async {
      await notifier.loadConversations();

      notifier.setFilter(1);
      expect(notifier.state.selectedFilterIndex, 1);

      notifier.search('Thomas');
      expect(notifier.state.searchQuery, 'Thomas');
      expect(
        notifier.state.displayedConversations.every(
          (c) => c.name.contains('Thomas'),
        ),
        isTrue,
      );
    });

    test('togglePin toggles conversation isPinned flag', () async {
      await notifier.loadConversations();
      final firstChat = notifier.state.conversations.first;
      final initialPinned = firstChat.isPinned;

      await notifier.togglePin(firstChat.id);
      final updatedChat =
          notifier.state.conversations.firstWhere((c) => c.id == firstChat.id);
      expect(updatedChat.isPinned, !initialPinned);
    });
  });
}
