import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/message.dart';
import '../../repository/texting_repository.dart';
import '../../services/message_draft_service.dart';
import '../../services/texting_socket_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
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
      emit(state.copyWith(draftText: draft));
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
      emit(state.copyWith(messages: [...state.messages, msg]));
    }
  }

  void _handleTyping(String userId, bool isTyping) {
    if (userId == otherUserId) {
      emit(state.copyWith(isOtherUserTyping: isTyping));
    }
  }

  Future<void> loadMessages() async {
    emit(state.copyWith(status: ChatStatus.loading));

    final result = await repository.fetchMessages(chatId, myUserId: myUserId);
    result.fold(
      (failure) {
        // If messages are already present (from conversation preview or mock), don't wipe
        if (state.messages.isEmpty) {
          emit(state.copyWith(status: ChatStatus.error, errorMessage: failure.message));
        } else {
          emit(state.copyWith(status: ChatStatus.loaded));
        }
      },
      (msgs) {
        emit(state.copyWith(status: ChatStatus.loaded, messages: msgs));
      },
    );
  }

  void setReplyingTo(Message? message) {
    emit(state.copyWith(replyingTo: message, clearReplyingTo: message == null));
  }

  void onDraftChanged(String text) {
    MessageDraftService.saveDraft(chatId, text);
    emit(state.copyWith(draftText: text));
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

    emit(
      state.copyWith(
        messages: [...state.messages, optimisticMsg],
        clearReplyingTo: true,
        draftText: '',
      ),
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
        emit(state.copyWith(messages: updated, errorMessage: failure.message));
      },
      (sentMsg) {
        // Replace optimistic msg with server msg
        final updated = state.messages.map((m) {
          if (m.id == optimisticMsg.id) return sentMsg;
          return m;
        }).toList();
        emit(state.copyWith(messages: updated));
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

    emit(state.copyWith(messages: [...state.messages, optimisticMsg]));

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
        emit(state.copyWith(messages: updated, errorMessage: failure.message));
      },
      (sentMsg) {
        final updated = state.messages.map((m) {
          if (m.id == optimisticMsg.id) return sentMsg;
          return m;
        }).toList();
        emit(state.copyWith(messages: updated));
      },
    );
  }

  @override
  Future<void> close() {
    socketService.leaveChat(chatId);
    return super.close();
  }
}
