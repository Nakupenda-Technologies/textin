import '../../../config/constants/endpoints.dart';
import '../../../core/network/client.dart';
import '../models/api/chat_item.dart';
import '../models/api/chat_message_api.dart';
import '../models/api/chat_streak.dart';
import '../models/following_user.dart';

abstract class TextingRemoteDataSource {
  Future<List<ChatItem>> fetchRegularChats(int filterIndex);
  Future<List<ChatItem>> fetchSecretChats();
  Future<List<ChatMessageApi>> fetchMessages(String chatId);
  Future<ChatMessageApi> sendTextMessage(
    String chatId,
    String text, {
    String? replyToId,
  });
  Future<ChatMessageApi> sendVoiceMessage(
    String chatId,
    String mediaUrl,
    int durationSec, {
    String? replyToId,
  });
  Future<ChatMessageApi> sendImageMessage(
    String chatId,
    String mediaUrl, {
    String? replyToId,
  });
  Future<void> markChatRead(String chatId);
  Future<void> togglePin(String chatId, bool pinned);
  Future<void> toggleSecretInbox(String chatId, bool inSecretInbox);
  Future<ChatStreak?> fetchStreak(String chatId);
  Future<ChatItem> startOrGetChat({
    required String otherUserId,
    String? matchId,
  });
  Future<List<FollowingUser>> fetchFollowingUsers(String username);
}

class TextingRemoteDataSourceImpl implements TextingRemoteDataSource {
  TextingRemoteDataSourceImpl(this.client);

  final BaseApiClients client;

  @override
  Future<List<ChatItem>> fetchRegularChats(int filterIndex) async {
    final params = {
      'filter': _filterString(filterIndex),
      'includeSecretInbox': 'false',
      'secretInboxOnly': 'false',
      'limit': '20',
    };
    final dynamic response = await client.get(
      Endpoints.startOrGetChat,
      queryParameters: params,
    );
    if (response is Map<String, dynamic>) {
      return ChatListResponse.fromJson(response).chats;
    }
    return [];
  }

  @override
  Future<List<ChatItem>> fetchSecretChats() async {
    final dynamic response = await client.get(
      Endpoints.startOrGetChat,
      queryParameters: {'secretInboxOnly': 'true', 'limit': '50'},
    );
    if (response is Map<String, dynamic>) {
      return ChatListResponse.fromJson(response).chats;
    }
    return [];
  }

  @override
  Future<List<ChatMessageApi>> fetchMessages(String chatId) async {
    final dynamic response = await client.get(Endpoints.chatMessages(chatId));
    if (response is Map<String, dynamic>) {
      return ChatMessagesResponse.fromJson(response).messages;
    }
    return [];
  }

  @override
  Future<ChatMessageApi> sendTextMessage(
    String chatId,
    String text, {
    String? replyToId,
  }) async {
    final dynamic response = await client.post(
      Endpoints.chatMessages(chatId),
      body: {
        'type': 'text',
        'content': text,
        'replyToId': ?replyToId,
      },
    );
    return ChatMessageApi.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ChatMessageApi> sendVoiceMessage(
    String chatId,
    String mediaUrl,
    int durationSec, {
    String? replyToId,
  }) async {
    final dynamic response = await client.post(
      Endpoints.chatMessages(chatId),
      body: {
        'type': 'voice',
        'mediaUrl': mediaUrl,
        'voiceDurationSeconds': durationSec,
        'replyToId': ?replyToId,
      },
    );
    return ChatMessageApi.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ChatMessageApi> sendImageMessage(
    String chatId,
    String mediaUrl, {
    String? replyToId,
  }) async {
    final dynamic response = await client.post(
      Endpoints.chatMessages(chatId),
      body: {
        'type': 'image',
        'mediaUrl': mediaUrl,
        'replyToId': ?replyToId,
      },
    );
    return ChatMessageApi.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> markChatRead(String chatId) async {
    await client.patch(Endpoints.markChatRead(chatId), body: {});
  }

  @override
  Future<void> togglePin(String chatId, bool pinned) async {
    await client.patch(Endpoints.chatPin(chatId), body: {'pinned': pinned});
  }

  @override
  Future<void> toggleSecretInbox(String chatId, bool inSecretInbox) async {
    await client.patch(
      Endpoints.chatSecretInbox(chatId),
      body: {'inSecretInbox': inSecretInbox},
    );
  }

  @override
  Future<ChatStreak?> fetchStreak(String chatId) async {
    try {
      final dynamic response = await client.get(Endpoints.chatStreak(chatId));
      if (response is Map<String, dynamic>) {
        return ChatStreak.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<ChatItem> startOrGetChat({
    required String otherUserId,
    String? matchId,
  }) async {
    final dynamic response = await client.post(
      Endpoints.startOrGetChat,
      body: {
        'otherUserId': otherUserId,
        'matchId': ?matchId,
      },
    );
    return ChatItem.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<FollowingUser>> fetchFollowingUsers(String username) async {
    final dynamic response = await client.get(Endpoints.userFollowing(username));
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => FollowingUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  String _filterString(int index) {
    switch (index) {
      case 1:
        return 'unread';
      case 2:
        return 'aura_active';
      case 3:
        return 'archived';
      default:
        return 'all';
    }
  }
}
