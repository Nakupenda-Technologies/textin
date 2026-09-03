import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../repository/texting_repository.dart';
import '../../services/texting_socket_service.dart';
import 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  InboxCubit({
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

    emit(state.copyWith(conversations: updatedList));
  }

  void _handleSocketTyping(String userId, bool isTyping) {
    final updatedTyping = Set<String>.from(state.typingUserIds);
    if (isTyping) {
      updatedTyping.add(userId);
    } else {
      updatedTyping.remove(userId);
    }
    emit(state.copyWith(typingUserIds: updatedTyping));
  }

  Future<void> loadConversations() async {
    emit(state.copyWith(status: InboxStatus.loading));

    final result = await repository.fetchRegularChats(
      state.selectedFilterIndex,
      myUserId: myUserId,
    );

    result.fold(
      (failure) {
        // If API fails or backend is offline, fall back to mock data for instant preview
        if (state.conversations.isEmpty) {
          emit(
            state.copyWith(
              status: InboxStatus.loaded,
              conversations: Conversation.mockData,
              errorMessage: failure.message,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: InboxStatus.error,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (chats) {
        emit(
          state.copyWith(
            status: InboxStatus.loaded,
            conversations: chats.isEmpty ? Conversation.mockData : chats,
          ),
        );
      },
    );
  }

  void setFilter(int index) {
    emit(state.copyWith(selectedFilterIndex: index));
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> togglePin(String chatId) async {
    final current = state.conversations.firstWhere((c) => c.id == chatId);
    final next = !current.isPinned;

    final updated = state.conversations.map((c) {
      if (c.id == chatId) return c.copyWith(isPinned: next);
      return c;
    }).toList();
    emit(state.copyWith(conversations: updated));

    await repository.togglePin(chatId, next);
  }

  Future<void> toggleSecretInbox(String chatId) async {
    final current = state.conversations.firstWhere((c) => c.id == chatId);
    final next = !current.inSecretInbox;

    final updated = state.conversations.map((c) {
      if (c.id == chatId) return c.copyWith(inSecretInbox: next);
      return c;
    }).toList();
    emit(state.copyWith(conversations: updated));

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
    emit(state.copyWith(conversations: updated));

    await repository.markChatRead(chatId);
  }

  @override
  Future<void> close() {
    socketService.disconnect();
    return super.close();
  }
}
