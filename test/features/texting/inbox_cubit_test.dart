import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/texting/cubit/inbox/inbox_cubit.dart';
import 'package:textin/features/texting/cubit/inbox/inbox_state.dart';
import 'package:textin/features/texting/models/api/chat_streak.dart';
import 'package:textin/features/texting/models/conversation.dart';
import 'package:textin/features/texting/models/following_user.dart';
import 'package:textin/features/texting/models/message.dart';
import 'package:textin/features/texting/repository/texting_repository.dart';
import 'package:textin/features/texting/services/texting_socket_service.dart';
import 'package:textin/services/local_storage_service.dart';
import 'package:textin/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  group('InboxCubit tests', () {
    late InboxCubit cubit;
    late MockTextingRepository repository;
    late TextingSocketService socketService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      repository = MockTextingRepository();
      socketService = TextingSocketService(WebSocketService());
      cubit = InboxCubit(
        repository: repository,
        socketService: socketService,
        myUserId: 'me',
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, InboxStatus.initial);
      expect(cubit.state.conversations, isEmpty);
      expect(cubit.state.selectedFilterIndex, 0);
    });

    test('loadConversations populates conversations', () async {
      await cubit.loadConversations();
      expect(cubit.state.status, InboxStatus.loaded);
      expect(cubit.state.conversations, isNotEmpty);
      expect(cubit.state.displayedConversations, isNotEmpty);
    });

    test('filter and search updates state properly', () async {
      await cubit.loadConversations();

      cubit.setFilter(1);
      expect(cubit.state.selectedFilterIndex, 1);

      cubit.search('Thomas');
      expect(cubit.state.searchQuery, 'Thomas');
      expect(
        cubit.state.displayedConversations.every(
          (c) => c.name.contains('Thomas'),
        ),
        isTrue,
      );
    });

    test('togglePin toggles conversation isPinned flag', () async {
      await cubit.loadConversations();
      final firstChat = cubit.state.conversations.first;
      final initialPinned = firstChat.isPinned;

      await cubit.togglePin(firstChat.id);
      final updatedChat =
          cubit.state.conversations.firstWhere((c) => c.id == firstChat.id);
      expect(updatedChat.isPinned, !initialPinned);
    });
  });
}
