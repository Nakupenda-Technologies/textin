import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/storage/shared_preferences_store.dart';
import 'package:textin/features/texting/models/api/chat_message_api.dart';
import 'package:textin/features/texting/models/api/chat_streak.dart';
import 'package:textin/features/texting/models/message.dart';
import 'package:textin/features/texting/notifier/chat_notifier.dart';
import 'package:textin/features/texting/services/texting_socket_service.dart';
import 'package:textin/services/websocket_service.dart';

import 'inbox_notifier_test.dart' show MockTextingRepository;

class _BlankReplyRepository extends MockTextingRepository {
  @override
  Future<Either<Failure, Message>> sendTextMessage(
    String chatId,
    String text, {
    String? replyToId,
    required String myUserId,
  }) async {
    return Right(
      Message(
        id: 'server_1',
        content: '',
        type: MessageType.text,
        isMe: false,
        timestamp: DateTime(2026, 10, 14, 18, 27),
      ),
    );
  }
}

class _UploadingRepository extends MockTextingRepository {
  String? sentPath;

  @override
  Future<Either<Failure, Message>> sendVoiceMessage(
    String chatId,
    String filePath,
    int durationSec, {
    String? replyToId,
    required String myUserId,
  }) async {
    sentPath = filePath;
    return Right(
      Message(
        id: 'server_voice',
        content: '',
        type: MessageType.voice,
        isMe: true,
        timestamp: DateTime(2026, 10, 14, 18, 27),
        mediaUrl: 'https://cdn.test/voice.m4a',
      ),
    );
  }
}

class _ImageUploadingRepository extends MockTextingRepository {
  String? sentPath;

  @override
  Future<Either<Failure, Message>> sendImageMessage(
    String chatId,
    String filePath, {
    String? replyToId,
    required String myUserId,
  }) async {
    sentPath = filePath;
    return Right(
      Message(
        id: 'server_image',
        content: '',
        type: MessageType.image,
        isMe: true,
        timestamp: DateTime(2026, 10, 14, 18, 27),
        mediaUrl: 'https://cdn.test/photo.jpg',
      ),
    );
  }
}

class _StreakRepository extends _BlankReplyRepository {
  _StreakRepository(this.streaks);

  final List<ChatStreak?> streaks;
  int fetches = 0;

  @override
  Future<Either<Failure, ChatStreak?>> fetchStreak(String chatId) async {
    final streak = streaks[fetches.clamp(0, streaks.length - 1)];
    fetches++;
    return Right(streak);
  }
}

class _FakeSocketService extends TextingSocketService {
  _FakeSocketService() : super(WebSocketService());

  final sentTyping = <bool>[];
  void Function(String chatId, String userId, bool isTyping)? typing;

  @override
  void Function() onTyping(
    void Function(String chatId, String userId, bool isTyping) callback,
  ) {
    typing = callback;
    return () => typing = null;
  }

  @override
  void sendTyping(String chatId, {required bool isTyping}) =>
      sentTyping.add(isTyping);
}

ChatNotifier _typingNotifier(_FakeSocketService socket) => ChatNotifier(
  chatId: 'chat_1',
  otherUserId: 'other',
  myUserId: 'me',
  repository: MockTextingRepository(),
  socketService: socket,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesStore.init();
  });

  test('a sent message keeps its text when the reply omits it', () async {
    final notifier = ChatNotifier(
      chatId: 'chat_1',
      otherUserId: 'other',
      myUserId: 'me',
      repository: _BlankReplyRepository(),
      socketService: TextingSocketService(WebSocketService()),
    );
    addTearDown(notifier.dispose);

    await notifier.sendText('Hiii');

    final sent = notifier.state.messages.single;
    expect(sent.id, 'server_1');
    expect(sent.content, 'Hiii');
    expect(sent.isMe, isTrue);
    expect(sent.status, MessageStatus.sent);
  });

  group('streak', () {
    final yesterday = ChatStreak(
      count: 4,
      level: 'bronze',
      lastActivityAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    final today = ChatStreak(
      count: 5,
      level: 'bronze',
      lastActivityAt: DateTime.now().toUtc(),
    );

    ChatNotifier streakNotifier(_StreakRepository repository) {
      final notifier = ChatNotifier(
        chatId: 'chat_1',
        otherUserId: 'other',
        myUserId: 'me',
        repository: repository,
        socketService: TextingSocketService(WebSocketService()),
      );
      addTearDown(notifier.dispose);
      return notifier;
    }

    test('loads when the chat opens', () async {
      final notifier = streakNotifier(_StreakRepository([yesterday]));
      await pumpEventQueue();

      expect(notifier.state.streak, yesterday);
    });

    test('refreshes after sending while today is not kept yet', () async {
      final repository = _StreakRepository([yesterday, today]);
      final notifier = streakNotifier(repository);
      await pumpEventQueue();

      await notifier.sendText('Hiii');
      await pumpEventQueue();

      expect(notifier.state.streak, today);
    });

    test('is not fetched again once today is kept', () async {
      final repository = _StreakRepository([today]);
      final notifier = streakNotifier(repository);
      await pumpEventQueue();

      await notifier.sendText('Hiii');
      await pumpEventQueue();

      expect(repository.fetches, 1);
    });
  });

  test('message payloads are unwrapped from message or data keys', () {
    const inner = {'id': 'm1', 'content': 'hi'};

    expect(ChatMessageApi.unwrap({'message': inner}), inner);
    expect(ChatMessageApi.unwrap({'data': inner}), inner);
    expect(ChatMessageApi.unwrap(inner), inner);
  });

  test('a voice note sends the recording and keeps the uploaded url', () async {
    final repository = _UploadingRepository();
    final notifier = ChatNotifier(
      chatId: 'chat_1',
      otherUserId: 'other',
      myUserId: 'me',
      repository: repository,
      socketService: TextingSocketService(WebSocketService()),
    );
    addTearDown(notifier.dispose);

    await notifier.sendVoiceNote('/tmp/voice.m4a', 6);

    final sent = notifier.state.messages.single;
    expect(repository.sentPath, '/tmp/voice.m4a');
    expect(sent.id, 'server_voice');
    expect(sent.mediaUrl, 'https://cdn.test/voice.m4a');
    expect(sent.localMediaPath, '/tmp/voice.m4a');
    expect(sent.voiceDuration, const Duration(seconds: 6));
    expect(sent.status, MessageStatus.sent);
  });

  test('an image sends the picked file and keeps the uploaded url', () async {
    final repository = _ImageUploadingRepository();
    final notifier = ChatNotifier(
      chatId: 'chat_1',
      otherUserId: 'other',
      myUserId: 'me',
      repository: repository,
      socketService: TextingSocketService(WebSocketService()),
    );
    addTearDown(notifier.dispose);

    await notifier.sendImage('/tmp/photo.jpg');

    final sent = notifier.state.messages.single;
    expect(repository.sentPath, '/tmp/photo.jpg');
    expect(sent.id, 'server_image');
    expect(sent.type, MessageType.image);
    expect(sent.mediaUrl, 'https://cdn.test/photo.jpg');
    expect(sent.localMediaPath, '/tmp/photo.jpg');
    expect(sent.status, MessageStatus.sent);
  });

  testWidgets('typing is sent once and stops after a pause', (tester) async {
    final socket = _FakeSocketService();
    final notifier = _typingNotifier(socket);

    notifier.emitTyping(true);
    notifier.emitTyping(true);
    notifier.emitTyping(true);
    expect(socket.sentTyping, [true]);

    await tester.pump(const Duration(seconds: 4));
    expect(socket.sentTyping, [true, false]);

    notifier.dispose();
  });

  testWidgets('the other user typing expires without updates', (tester) async {
    final socket = _FakeSocketService();
    final notifier = _typingNotifier(socket);

    socket.typing!('another_chat', 'other', true);
    expect(notifier.state.isOtherUserTyping, isFalse);

    socket.typing!('chat_1', 'other', true);
    expect(notifier.state.isOtherUserTyping, isTrue);

    await tester.pump(const Duration(seconds: 6));
    expect(notifier.state.isOtherUserTyping, isFalse);

    notifier.dispose();
    expect(socket.typing, isNull);
  });
}
