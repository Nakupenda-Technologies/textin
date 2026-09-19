import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/locator.dart';
import '../models/message.dart';
import '../repository/texting_repository.dart';
import '../services/texting_socket_service.dart';
import 'inbox_state.dart';

export 'inbox_state.dart';

final textingRepositoryProvider = Provider<TextingRepository>((ref) {
  return locator<TextingRepository>();
});

final textingSocketServiceProvider = Provider<TextingSocketService>((ref) {
  return locator<TextingSocketService>();
});

final myUserIdProvider = Provider<String>((ref) {
  return 'me';
});

final inboxNotifierProvider =
    StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final repository = ref.watch(textingRepositoryProvider);
  final socketService = ref.watch(textingSocketServiceProvider);
  final myUserId = ref.watch(myUserIdProvider);

  return InboxNotifier(
    repository: repository,
    socketService: socketService,
    myUserId: myUserId,
  );
});

class InboxNotifier extends StateNotifier<InboxState> {
  InboxNotifier({
    required this.repository,
    required this.socketService,
    required this.myUserId,
  }) : super(const InboxState()) {
    _initSocket();
  }

  final TextingRepository repository;
  final TextingSocketService socketService;
  final String myUserId;

  void _initSocket() {
    socketService.connect(
      onConnect: () {
        socketService.onNewMessage(_handleSocketMessage);
        socketService.onTyping(_handleSocketTyping);
      },
    );
  }

  void _handleSocketMessage(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    if (chatId == null) return;

    final newMsg = Message.fromJson(data, myUserId: myUserId);
    final updatedList = state.conversations.map((c) {
      if (c.id == chatId) {
        return c.copyWith(
          messages: [...c.messages, newMsg],
        );
      }
      return c;
    }).toList();

    state = state.copyWith(conversations: updatedList);
  }

  void _handleSocketTyping(String userId, bool isTyping) {
    final updatedTyping = Set<String>.from(state.typingUserIds);
    if (isTyping) {
      updatedTyping.add(userId);
    } else {
      updatedTyping.remove(userId);
    }
    state = state.copyWith(typingUserIds: updatedTyping);
  }

  Future<void> loadConversations() async {
    state = state.copyWith(status: InboxStatus.loading);

    final result = await repository.fetchRegularChats(
      state.selectedFilterIndex,
      myUserId: myUserId,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: InboxStatus.error,
          errorMessage: failure.message,
        );
      },
      (chats) {
        state = state.copyWith(
          status: InboxStatus.loaded,
          conversations: chats,
        );
      },
    );
  }

  void setFilter(int index) {
    state = state.copyWith(selectedFilterIndex: index);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> togglePin(String chatId) async {
    final current = state.conversations.firstWhere((c) => c.id == chatId);
    final next = !current.isPinned;

    final updated = state.conversations.map((c) {
      if (c.id == chatId) return c.copyWith(isPinned: next);
      return c;
    }).toList();
    state = state.copyWith(conversations: updated);

    await repository.togglePin(chatId, next);
  }

  Future<void> toggleSecretInbox(String chatId) async {
    final current = state.conversations.firstWhere((c) => c.id == chatId);
    final next = !current.inSecretInbox;

    final updated = state.conversations.map((c) {
      if (c.id == chatId) return c.copyWith(inSecretInbox: next);
      return c;
    }).toList();
    state = state.copyWith(conversations: updated);

    await repository.toggleSecretInbox(chatId, next);
  }

  Future<void> markRead(String chatId) async {
    final updated = state.conversations.map((c) {
      if (c.id == chatId) {
        final markedMsgs = c.messages.map((m) => m.copyWith(isRead: true)).toList();
        return c.copyWith(messages: markedMsgs);
      }
      return c;
    }).toList();
    state = state.copyWith(conversations: updated);

    await repository.markChatRead(chatId);
  }

  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }
}
