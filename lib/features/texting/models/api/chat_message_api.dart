import 'package:equatable/equatable.dart';

class ChatMessageApi extends Equatable {
  const ChatMessageApi({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.screenshotSensitive,
    required this.createdAt,
    this.content,
    this.mediaUrl,
    this.voiceDurationSeconds,
    this.warpEffect,
    this.expiresAt,
    this.whisperTtlSeconds,
    this.ephemeralTtlSeconds,
    this.replyToId,
  });

  factory ChatMessageApi.fromJson(Map<String, dynamic> json) {
    return ChatMessageApi(
      id: json['id'] as String? ?? '',
      chatId: json['chatId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      screenshotSensitive: json['screenshotSensitive'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      voiceDurationSeconds: (json['voiceDurationSeconds'] as num?)?.toInt(),
      warpEffect: json['warpEffect'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      whisperTtlSeconds: (json['whisperTtlSeconds'] as num?)?.toInt(),
      ephemeralTtlSeconds: (json['ephemeralTtlSeconds'] as num?)?.toInt(),
      replyToId: json['replyToId'] as String?,
    );
  }

  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final bool screenshotSensitive;
  final DateTime createdAt;
  final String? content;
  final String? mediaUrl;
  final int? voiceDurationSeconds;
  final String? warpEffect;
  final DateTime? expiresAt;
  final int? whisperTtlSeconds;
  final int? ephemeralTtlSeconds;
  final String? replyToId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'type': type,
    'screenshotSensitive': screenshotSensitive,
    'createdAt': createdAt.toIso8601String(),
    if (content != null) 'content': content,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    if (voiceDurationSeconds != null)
      'voiceDurationSeconds': voiceDurationSeconds,
    if (warpEffect != null) 'warpEffect': warpEffect,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (whisperTtlSeconds != null) 'whisperTtlSeconds': whisperTtlSeconds,
    if (ephemeralTtlSeconds != null)
      'ephemeralTtlSeconds': ephemeralTtlSeconds,
    if (replyToId != null) 'replyToId': replyToId,
  };

  @override
  List<Object?> get props => [
    id,
    chatId,
    senderId,
    type,
    screenshotSensitive,
    createdAt,
    content,
    mediaUrl,
    voiceDurationSeconds,
    warpEffect,
    expiresAt,
    whisperTtlSeconds,
    ephemeralTtlSeconds,
    replyToId,
  ];
}

class ChatMessagesResponse {
  const ChatMessagesResponse({
    required this.messages,
    this.nextCursor,
  });

  factory ChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['messages'] as List<dynamic>? ?? [];
    return ChatMessagesResponse(
      messages: list
          .map((e) => ChatMessageApi.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<ChatMessageApi> messages;
  final String? nextCursor;

  Map<String, dynamic> toJson() => {
    'messages': messages.map((m) => m.toJson()).toList(),
    if (nextCursor != null) 'nextCursor': nextCursor,
  };
}
