import 'package:equatable/equatable.dart';
import 'api/chat_message_api.dart';

enum MessageType { text, voice, emoji, image, warp, whisper }

enum MessageStatus { pending, sent, failed }

extension MessageTypeX on MessageType {
  static MessageType fromString(String? s) {
    switch (s) {
      case 'voice':
        return MessageType.voice;
      case 'emoji':
        return MessageType.emoji;
      case 'image':
        return MessageType.image;
      case 'warp':
        return MessageType.warp;
      case 'whisper':
        return MessageType.whisper;
      default:
        return MessageType.text;
    }
  }

  String get value {
    switch (this) {
      case MessageType.voice:
        return 'voice';
      case MessageType.emoji:
        return 'emoji';
      case MessageType.image:
        return 'image';
      case MessageType.warp:
        return 'warp';
      case MessageType.whisper:
        return 'whisper';
      case MessageType.text:
        return 'text';
    }
  }
}

class Message extends Equatable {
  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.voiceDuration,
    this.mediaUrl,
    this.localMediaPath,
    this.replyToId,
    this.status = MessageStatus.sent,
  });

  factory Message.fromApi(ChatMessageApi api, {required String myUserId}) {
    return Message(
      id: api.id,
      content: api.content ?? '',
      type: MessageTypeX.fromString(api.type),
      isMe: api.senderId == myUserId,
      timestamp: api.createdAt,
      voiceDuration: api.voiceDurationSeconds != null
          ? Duration(seconds: api.voiceDurationSeconds!)
          : null,
      mediaUrl: api.mediaUrl,
      replyToId: api.replyToId,
      status: MessageStatus.sent,
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    required String myUserId,
  }) {
    final durationSecs = (json['voiceDurationSeconds'] as num?)?.toInt();
    return Message(
      id: json['id'] as String? ?? json['messageId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: MessageTypeX.fromString(json['type'] as String?),
      isMe: (json['senderId'] as String?) == myUserId,
      timestamp:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      voiceDuration:
          durationSecs != null ? Duration(seconds: durationSecs) : null,
      mediaUrl: json['mediaUrl'] as String?,
      replyToId: json['replyToId'] as String?,
      status: MessageStatus.sent,
    );
  }

  final String id;
  final String content;
  final MessageType type;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final Duration? voiceDuration;
  final String? mediaUrl;
  final String? localMediaPath;
  final String? replyToId;
  final MessageStatus status;

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    bool? isMe,
    DateTime? timestamp,
    bool? isRead,
    Duration? voiceDuration,
    String? mediaUrl,
    String? localMediaPath,
    String? replyToId,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      localMediaPath: localMediaPath ?? this.localMediaPath,
      replyToId: replyToId ?? this.replyToId,
      status: status ?? this.status,
    );
  }

  String get formattedTime {
    final h = timestamp.hour;
    final m = timestamp.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'pm' : 'am';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m$period';
  }

  String get formattedDuration {
    if (voiceDuration == null) return '00:00';
    final m =
        voiceDuration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
        voiceDuration!.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  List<Object?> get props => [
    id,
    content,
    type,
    isMe,
    timestamp,
    isRead,
    voiceDuration,
    mediaUrl,
    localMediaPath,
    replyToId,
    status,
  ];
}
