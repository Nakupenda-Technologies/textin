import 'package:equatable/equatable.dart';
import '../models/conversation.dart';

enum InboxStatus { initial, loading, loaded, error }

class InboxState extends Equatable {
  const InboxState({
    this.status = InboxStatus.initial,
    this.conversations = const [],
    this.selectedFilterIndex = 0,
    this.searchQuery = '',
    this.errorMessage,
    this.typingUserIds = const {},
  });

  final InboxStatus status;
  final List<Conversation> conversations;
  final int selectedFilterIndex;
  final String searchQuery;
  final String? errorMessage;
  final Set<String> typingUserIds;

  List<Conversation> get displayedConversations {
    var list = conversations.where((c) => !c.inSecretInbox).toList();

    // Filter index
    switch (selectedFilterIndex) {
      case 1: // Unread
        list = list.where((c) => c.unreadCount > 0).toList();
        break;
      case 2: // Active
        list = list.where((c) => c.isOnline || c.hasFireBadge).toList();
        break;
      case 3: // Archived (if tagged)
        list = list.where((c) => c.tag == ConversationTag.none).toList();
        break;
      default:
        break;
    }

    // Search query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    // Sort: pinned first, then last message timestamp
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final aTime = a.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessage?.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return list;
  }

  int get totalUnreadCount =>
      conversations.where((c) => !c.inSecretInbox).fold(0, (sum, c) => sum + c.unreadCount);

  InboxState copyWith({
    InboxStatus? status,
    List<Conversation>? conversations,
    int? selectedFilterIndex,
    String? searchQuery,
    String? errorMessage,
    Set<String>? typingUserIds,
  }) {
    return InboxState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      typingUserIds: typingUserIds ?? this.typingUserIds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversations,
    selectedFilterIndex,
    searchQuery,
    errorMessage,
    typingUserIds,
  ];
}
