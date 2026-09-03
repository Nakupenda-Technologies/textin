import 'package:equatable/equatable.dart';
import 'chat_message_api.dart';
import 'chat_participant.dart';

class ChatItem extends Equatable {
  const ChatItem({
    required this.id,
    required this.otherUser,
    required this.otherParticipant,
    required this.unreadCount,
    required this.pinned,
    required this.isPinned,
    this.inSecretInbox = false,
    required this.boundaryTriggered,
    required this.updatedAt,
    this.lastMessage,
    this.customization,
    this.lastSeen,
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) {
    final otherUserData = (json['otherUser'] ?? json['otherParticipant'] ?? {})
        as Map<String, dynamic>;
    final participant = ChatParticipant.fromJson(otherUserData);

    return ChatItem(
      id: json['id'] as String? ?? '',
      otherUser: participant,
      otherParticipant: participant,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      pinned: json['pinned'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? json['pinned'] as bool? ?? false,
      inSecretInbox: json['inSecretInbox'] as bool? ?? false,
      boundaryTriggered: json['boundaryTriggered'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      lastMessage: json['lastMessage'] != null
          ? ChatMessageApi.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      customization: json['customization'] as Map<String, dynamic>?,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
    );
  }

  final String id;
  final ChatParticipant otherUser;
  final ChatParticipant otherParticipant;
  final int unreadCount;
  final bool pinned;
  final bool isPinned;
  final bool inSecretInbox;
  final bool boundaryTriggered;
  final DateTime updatedAt;
  final ChatMessageApi? lastMessage;
  final Map<String, dynamic>? customization;
  final DateTime? lastSeen;

  Map<String, dynamic> toJson() => {
    'id': id,
    'otherUser': otherUser.toJson(),
    'otherParticipant': otherParticipant.toJson(),
    'unreadCount': unreadCount,
    'pinned': pinned,
    'isPinned': isPinned,
    'inSecretInbox': inSecretInbox,
    'boundaryTriggered': boundaryTriggered,
    'updatedAt': updatedAt.toIso8601String(),
    if (lastMessage != null) 'lastMessage': lastMessage!.toJson(),
    if (customization != null) 'customization': customization,
    if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    otherUser,
    otherParticipant,
    unreadCount,
    pinned,
    isPinned,
    inSecretInbox,
    boundaryTriggered,
    updatedAt,
    lastMessage,
    customization,
    lastSeen,
  ];
}

class ChatListResponse {
  const ChatListResponse({
    required this.chats,
    this.nextCursor,
  });

  factory ChatListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['chats'] as List<dynamic>? ?? [];
    return ChatListResponse(
      chats: list
          .map((e) => ChatItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<ChatItem> chats;
  final String? nextCursor;

  Map<String, dynamic> toJson() => {
    'chats': chats.map((c) => c.toJson()).toList(),
    if (nextCursor != null) 'nextCursor': nextCursor,
  };
}
