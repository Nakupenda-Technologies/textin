import 'package:equatable/equatable.dart';
import '../models/conversation.dart';

enum SecretBoxStatus { locked, unlocked, settingUpPin }

class SecretBoxState extends Equatable {
  const SecretBoxState({
    this.status = SecretBoxStatus.locked,
    this.secretConversations = const [],
    this.hasPin = false,
    this.errorMessage,
  });

  final SecretBoxStatus status;
  final List<Conversation> secretConversations;
  final bool hasPin;
  final String? errorMessage;

  SecretBoxState copyWith({
    SecretBoxStatus? status,
    List<Conversation>? secretConversations,
    bool? hasPin,
    String? errorMessage,
  }) {
    return SecretBoxState(
      status: status ?? this.status,
      secretConversations: secretConversations ?? this.secretConversations,
      hasPin: hasPin ?? this.hasPin,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    secretConversations,
    hasPin,
    errorMessage,
  ];
}
