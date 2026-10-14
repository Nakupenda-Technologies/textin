import 'package:equatable/equatable.dart';
import 'api/chat_item.dart';
import 'chat_customization.dart';
import 'message.dart';

enum ConversationTag { romantic, professional, chill, excited, none }

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastSeen,
    this.updatedAt,
    this.isPinned = false,
    this.isOnline = false,
    this.hasFireBadge = false,
    this.inSecretInbox = false,
    this.tag = ConversationTag.none,
    this.customization,
    this.messages = const [],
  });

  factory Conversation.fromChatItem(ChatItem item, {required String myUserId}) {
    final customization = item.customization != null
        ? ChatCustomization.fromJson(item.customization!)
        : null;
    return Conversation(
      id: item.id,
      name: item.otherUser.displayName,
      avatarUrl: item.otherUser.profilePictureUrl,
      lastSeen: item.otherUser.lastSeen,
      updatedAt: item.updatedAt,
      isPinned: item.isPinned,
      inSecretInbox: item.inSecretInbox,
      tag: customization?.mood ?? ConversationTag.none,
      customization: customization,
      messages: item.lastMessage != null
          ? [Message.fromApi(item.lastMessage!, myUserId: myUserId)]
          : [],
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime? lastSeen;
  final DateTime? updatedAt;
  final bool isPinned;
  final bool isOnline;
  final bool hasFireBadge;
  final bool inSecretInbox;
  final ConversationTag tag;
  final ChatCustomization? customization;
  final List<Message> messages;

  bool get isPinnable => !inSecretInbox;

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  int get unreadCount => messages.where((m) => !m.isMe && !m.isRead).length;

  String get timeAgo {
    final at = lastMessage?.timestamp ?? updatedAt;
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Conversation copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    DateTime? lastSeen,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isOnline,
    bool? hasFireBadge,
    bool? inSecretInbox,
    ConversationTag? tag,
    ChatCustomization? customization,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastSeen: lastSeen ?? this.lastSeen,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isOnline: isOnline ?? this.isOnline,
      hasFireBadge: hasFireBadge ?? this.hasFireBadge,
      inSecretInbox: inSecretInbox ?? this.inSecretInbox,
      tag: tag ?? this.tag,
      customization: customization ?? this.customization,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    avatarUrl,
    lastSeen,
    updatedAt,
    isPinned,
    isOnline,
    hasFireBadge,
    inSecretInbox,
    tag,
    customization,
    messages,
  ];
}

