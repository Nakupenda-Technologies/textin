import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/storage/shared_preferences_store.dart';
import 'package:textin/features/texting/models/api/chat_message_api.dart';
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
}
