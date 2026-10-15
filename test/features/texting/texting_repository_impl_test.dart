import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/texting/data_source/texting_remote_data_source.dart';
import 'package:textin/features/texting/models/api/chat_message_api.dart';
import 'package:textin/features/texting/repository/texting_repository_impl.dart';

class _RecordingRemoteDataSource implements TextingRemoteDataSource {
  final uploadedContentTypes = <String>[];

  @override
  Future<String> uploadMedia(String filePath, String contentType) async {
    uploadedContentTypes.add(contentType);
    return 'https://cdn.test/file';
  }

  @override
  Future<ChatMessageApi> sendVoiceMessage(
    String chatId,
    String mediaUrl,
    int durationSec, {
    String? replyToId,
  }) async => _message('voice');

  @override
  Future<ChatMessageApi> sendImageMessage(
    String chatId,
    String mediaUrl, {
    String? replyToId,
  }) async => _message('image');

  ChatMessageApi _message(String type) => ChatMessageApi(
    id: 'm1',
    chatId: 'chat_1',
    senderId: 'me',
    type: type,
    screenshotSensitive: false,
    createdAt: DateTime(2026, 10, 14),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('uploads use the content type of the file extension', () async {
    final remote = _RecordingRemoteDataSource();
    final repository = TextingRepositoryImpl(remote);

    for (final path in ['/a/note.m4a', '/a/song.MP3', '/a/clip.wav']) {
      await repository.sendVoiceMessage('chat_1', path, 3, myUserId: 'me');
    }
    for (final path in ['/a/photo.jpg', '/a/shot.png', '/a/pic.webp']) {
      await repository.sendImageMessage('chat_1', path, myUserId: 'me');
    }

    expect(remote.uploadedContentTypes, [
      'audio/mp4',
      'audio/mpeg',
      'audio/wav',
      'image/jpeg',
      'image/png',
      'image/webp',
    ]);
  });
}
