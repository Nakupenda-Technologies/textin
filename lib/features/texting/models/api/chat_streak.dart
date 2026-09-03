import 'package:equatable/equatable.dart';

class ChatStreak extends Equatable {
  const ChatStreak({
    required this.count,
    required this.isActive,
    this.lastMessageAt,
  });

  factory ChatStreak.fromJson(Map<String, dynamic> json) {
    return ChatStreak(
      count: json['count'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
    );
  }

  final int count;
  final bool isActive;
  final DateTime? lastMessageAt;

  Map<String, dynamic> toJson() => {
    'count': count,
    'isActive': isActive,
    if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
  };

  @override
  List<Object?> get props => [count, isActive, lastMessageAt];
}
