import 'package:equatable/equatable.dart';
import '../models/message.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.isOtherUserTyping = false,
    this.isSending = false,
    this.replyingTo,
    this.errorMessage,
    this.draftText = '',
  });

  final ChatStatus status;
  final List<Message> messages;
  final bool isOtherUserTyping;
  final bool isSending;
  final Message? replyingTo;
  final String? errorMessage;
  final String draftText;

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    bool? isOtherUserTyping,
    bool? isSending,
    Message? replyingTo,
    bool clearReplyingTo = false,
    String? errorMessage,
    String? draftText,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      isSending: isSending ?? this.isSending,
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      errorMessage: errorMessage ?? this.errorMessage,
      draftText: draftText ?? this.draftText,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    isOtherUserTyping,
    isSending,
    replyingTo,
    errorMessage,
    draftText,
  ];
}
