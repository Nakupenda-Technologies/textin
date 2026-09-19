import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../repository/texting_repository.dart';
import '../services/message_draft_service.dart';
import '../services/texting_socket_service.dart';
import 'chat_state.dart';
import 'inbox_notifier.dart';

export 'chat_state.dart';

class ChatArgs extends Equatable {
  const ChatArgs({
    required this.chatId,
    required this.otherUserId,
    required this.myUserId,
    this.initialMessages = const [],
  });

  final String chatId;
  final String otherUserId;
  final String myUserId;
  final List<Message> initialMessages;

  @override
  List<Object?> get props => [chatId, otherUserId, myUserId, initialMessages];
}

final chatNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, ChatArgs>((ref, args) {
  final repository = ref.watch(textingRepositoryProvider);
  final socketService = ref.watch(textingSocketServiceProvider);

  return ChatNotifier(
    chatId: args.chatId,
    otherUserId: args.otherUserId,
    myUserId: args.myUserId,
    repository: repository,
    socketService: socketService,
    initialMessages: args.initialMessages,
  );
});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required this.chatId,
    required this.otherUserId,
    required this.myUserId,
    required this.repository,
    required this.socketService,
    List<Message> initialMessages = const [],
  }) : super(ChatState(messages: initialMessages)) {
    _init();
  }

  final String chatId;
  final String otherUserId;
  final String myUserId;
  final TextingRepository repository;
  final TextingSocketService socketService;

  void _init() {
    final draft = MessageDraftService.getDraft(chatId) ?? '';
    if (draft.isNotEmpty) {
      state = state.copyWith(draftText: draft);
    }

    socketService.joinChat(chatId);
    socketService.onNewMessage(_handleIncomingMessage);
    socketService.onTyping(_handleTyping);
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final incomingChatId = data['chatId'] as String?;
    if (incomingChatId != chatId) return;

    final msg = Message.fromJson(data, myUserId: myUserId);
    final exists = state.messages.any((m) => m.id == msg.id);
    if (!exists) {
      state = state.copyWith(messages: [...state.messages, msg]);
    }
  }

  void _handleTyping(String userId, bool isTyping) {
    if (userId == otherUserId) {
      state = state.copyWith(isOtherUserTyping: isTyping);
    }
  }

  Future<void> loadMessages() async {
    state = state.copyWith(status: ChatStatus.loading);

    final result = await repository.fetchMessages(chatId, myUserId: myUserId);
    result.fold(
      (failure) {
        if (state.messages.isEmpty) {
          state = state.copyWith(status: ChatStatus.error, errorMessage: failure.message);
        } else {
          state = state.copyWith(status: ChatStatus.loaded);
        }
      },
      (msgs) {
        state = state.copyWith(status: ChatStatus.loaded, messages: msgs);
      },
    );
  }

  void setReplyingTo(Message? message) {
    state = state.copyWith(replyingTo: message, clearReplyingTo: message == null);
  }

  void onDraftChanged(String text) {
    MessageDraftService.saveDraft(chatId, text);
    state = state.copyWith(draftText: text);
  }

  void emitTyping(bool isTyping) {
    socketService.sendTyping(chatId, isTyping: isTyping);
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;

    final replyId = state.replyingTo?.id;
    final optimisticMsg = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      content: text.trim(),
      type: MessageType.text,
      isMe: true,
      timestamp: DateTime.now(),
      replyToId: replyId,
      status: MessageStatus.pending,
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      clearReplyingTo: true,
      draftText: '',
    );
    MessageDraftService.clearDraft(chatId);

    final result = await repository.sendTextMessage(
      chatId,
      text.trim(),
      replyToId: replyId,
      myUserId: myUserId,
    );

    result.fold(
      (failure) {
        // Mark failed
        final updated = state.messages.map((m) {
          if (m.id == optimisticMsg.id) {
            return m.copyWith(status: MessageStatus.failed);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updated, errorMessage: failure.message);
      },
      (sentMsg) {
        // Replace optimistic msg with server msg
        final updated = state.messages.map((m) {
          if (m.id == optimisticMsg.id) return sentMsg;
          return m;
        }).toList();
        state = state.copyWith(messages: updated);
      },
    );
  }

  Future<void> sendVoiceNote(String mediaUrl, int durationSec) async {
    final optimisticMsg = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      type: MessageType.voice,
      isMe: true,
      timestamp: DateTime.now(),
      voiceDuration: Duration(seconds: durationSec),
      mediaUrl: mediaUrl,
      status: MessageStatus.pending,
    );

    state = state.copyWith(messages: [...state.messages, optimisticMsg]);

    final result = await repository.sendVoiceMessage(
      chatId,
      mediaUrl,
      durationSec,
      myUserId: myUserId,
    );

    result.fold(
      (failure) {
        final updated = state.messages.map((m) {
          if (m.id == optimisticMsg.id) {
            return m.copyWith(status: MessageStatus.failed);
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updated, errorMessage: failure.message);
      },
      (sentMsg) {
        final updated = state.messages.map((m) {
          if (m.id == optimisticMsg.id) return sentMsg;
          return m;
        }).toList();
        state = state.copyWith(messages: updated);
      },
    );
  }

  @override
  void dispose() {
    socketService.leaveChat(chatId);
    super.dispose();
  }
}
