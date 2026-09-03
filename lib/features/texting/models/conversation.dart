import 'package:equatable/equatable.dart';
import 'api/chat_item.dart';
import 'message.dart';

enum ConversationTag { romantic, professional, chill, excited, none }

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isPinned = false,
    this.isOnline = false,
    this.hasFireBadge = false,
    this.inSecretInbox = false,
    this.tag = ConversationTag.none,
    this.messages = const [],
  });

  factory Conversation.fromChatItem(ChatItem item, {required String myUserId}) {
    return Conversation(
      id: item.id,
      name: item.otherUser.displayName,
      avatarUrl: item.otherUser.profilePictureUrl,
      isPinned: item.isPinned,
      inSecretInbox: item.inSecretInbox,
      messages: item.lastMessage != null
          ? [Message.fromApi(item.lastMessage!, myUserId: myUserId)]
          : [],
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
  final bool isPinned;
  final bool isOnline;
  final bool hasFireBadge;
  final bool inSecretInbox;
  final ConversationTag tag;
  final List<Message> messages;

  bool get isPinnable => !inSecretInbox;

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  int get unreadCount => messages.where((m) => !m.isMe && !m.isRead).length;

  String get timeAgo {
    if (lastMessage == null) return '';
    final diff = DateTime.now().difference(lastMessage!.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Conversation copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isPinned,
    bool? isOnline,
    bool? hasFireBadge,
    bool? inSecretInbox,
    ConversationTag? tag,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPinned: isPinned ?? this.isPinned,
      isOnline: isOnline ?? this.isOnline,
      hasFireBadge: hasFireBadge ?? this.hasFireBadge,
      inSecretInbox: inSecretInbox ?? this.inSecretInbox,
      tag: tag ?? this.tag,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    avatarUrl,
    isPinned,
    isOnline,
    hasFireBadge,
    inSecretInbox,
    tag,
    messages,
  ];

  static List<Conversation> get mockData {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return [
      Conversation(
        id: '1',
        name: 'Thomas Baker',
        isPinned: true,
        isOnline: true,
        hasFireBadge: true,
        tag: ConversationTag.romantic,
        messages: [
          Message(
            id: 'm1',
            content: 'Good afternoon!',
            type: MessageType.text,
            isMe: false,
            timestamp: yesterday,
          ),
          Message(
            id: 'm2',
            content: 'Hey Thomas, how is the project going?',
            type: MessageType.text,
            isMe: true,
            timestamp: now.subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
      Conversation(
        id: '2',
        name: 'Andrew Harris',
        isPinned: false,
        isOnline: true,
        hasFireBadge: true,
        tag: ConversationTag.professional,
        messages: [
          Message(
            id: 'm10',
            content: 'I really appreciate our meeting today.',
            type: MessageType.text,
            isMe: false,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      Conversation(
        id: '3',
        name: 'Lily Lee',
        isPinned: false,
        isOnline: false,
        hasFireBadge: false,
        tag: ConversationTag.excited,
        messages: [
          Message(
            id: 'm13',
            content: 'Hey! Are you available to chat later tonight?',
            type: MessageType.text,
            isMe: false,
            isRead: true,
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
    ];
  }
}
