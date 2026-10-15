import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_customization.dart';
import '../models/message.dart';
import '../repository/texting_repository.dart';
import '../services/chat_customization_store.dart';
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
    this.initialCustomization,
  });

  final String chatId;
  final String otherUserId;
  final String myUserId;
  final List<Message> initialMessages;
  final ChatCustomization? initialCustomization;

  @override
  List<Object?> get props => [
    chatId,
    otherUserId,
    myUserId,
    initialMessages,
    initialCustomization,
  ];
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
    initialCustomization: args.initialCustomization,
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
    ChatCustomization? initialCustomization,
  }) : super(
         ChatState(
           messages: initialMessages,
           customization: ChatCustomizationStore.read(chatId) ??
               initialCustomization ??
               const ChatCustomization(),
         ),
       ) {
    _init();
  }

  final String chatId;
  final String otherUserId;
  final String myUserId;
  final TextingRepository repository;
  final TextingSocketService socketService;
  List<void Function()> _socketSubscriptions = const [];

  void _init() {
    final draft = MessageDraftService.getDraft(chatId) ?? '';
    if (draft.isNotEmpty) {
      state = state.copyWith(draftText: draft);
    }

    socketService.joinChat(chatId);
    _socketSubscriptions = [
      socketService.onNewMessage(_handleIncomingMessage),
      socketService.onTyping(_handleTyping),
    ];
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final incomingChatId = data['chatId'] as String?;
    if (incomingChatId != chatId) return;

    final msg = Message.fromJson(data, myUserId: myUserId);
    if (msg.id.isEmpty || state.messages.any((m) => m.id == msg.id)) return;

    final pendingIndex = msg.isMe
        ? state.messages.indexWhere(
            (m) => m.status == MessageStatus.pending && m.content == msg.content,
          )
        : -1;
    if (pendingIndex >= 0) {
      final updated = [...state.messages]..[pendingIndex] = msg;
      state = state.copyWith(messages: updated);
      return;
    }

    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void _handleTyping(String typingChatId, String userId, bool isTyping) {
    if (typingChatId == chatId && userId == otherUserId) {
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

  Future<void> updateCustomization(ChatCustomization customization) async {
    if (customization == state.customization) return;

    state = state.copyWith(customization: customization);
    await ChatCustomizationStore.save(chatId, customization);
    // The backend's customization payload is unconfirmed, so the local copy
    // stays the source of truth and a failed sync is not surfaced.
    await repository.updateCustomization(chatId, customization);
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
      (sentMsg) => _confirmSent(optimisticMsg, sentMsg),
    );
  }

  Future<void> sendVoiceNote(String filePath, int durationSec) async {
    final replyId = state.replyingTo?.id;
    final optimisticMsg = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      type: MessageType.voice,
      isMe: true,
      timestamp: DateTime.now(),
      voiceDuration: Duration(seconds: durationSec),
      localMediaPath: filePath,
      replyToId: replyId,
      status: MessageStatus.pending,
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      clearReplyingTo: true,
    );

    final result = await repository.sendVoiceMessage(
      chatId,
      filePath,
      durationSec,
      replyToId: replyId,
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
      (sentMsg) => _confirmSent(optimisticMsg, sentMsg),
    );
  }

  Future<void> sendImage(String filePath) async {
    final replyId = state.replyingTo?.id;
    final optimisticMsg = Message(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      type: MessageType.image,
      isMe: true,
      timestamp: DateTime.now(),
      localMediaPath: filePath,
      replyToId: replyId,
      status: MessageStatus.pending,
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      clearReplyingTo: true,
    );

    final result = await repository.sendImageMessage(
      chatId,
      filePath,
      replyToId: replyId,
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
      (sentMsg) => _confirmSent(optimisticMsg, sentMsg),
    );
  }

  void _confirmSent(Message optimistic, Message sent) {
    if (!state.messages.any((m) => m.id == optimistic.id)) return;

    final hasServerId = sent.id.isNotEmpty;
    final confirmed = optimistic.copyWith(
      id: hasServerId ? sent.id : null,
      timestamp: hasServerId ? sent.timestamp : null,
      mediaUrl: sent.mediaUrl,
      status: MessageStatus.sent,
    );
    final updated = state.messages
        .where((m) => m.id != confirmed.id || m.id == optimistic.id)
        .map((m) => m.id == optimistic.id ? confirmed : m)
        .toList();
    state = state.copyWith(messages: updated);
  }

  @override
  void dispose() {
    for (final cancel in _socketSubscriptions) {
      cancel();
    }
    socketService.leaveChat(chatId);
    super.dispose();
  }
}
