import 'package:equatable/equatable.dart';

class ChatStreak extends Equatable {
  const ChatStreak({
    required this.count,
    required this.level,
    this.lastActivityAt,
  });

  // The backend streak is a score that grows once per active UTC day and
  // decays while the chat is quiet, so it arrives as a fractional value.
  factory ChatStreak.fromJson(Map<String, dynamic> json) {
    return ChatStreak(
      count: (json['value'] as num?)?.floor() ?? 0,
      level: json['level'] as String? ?? '',
      lastActivityAt: DateTime.tryParse(
        json['lastActivityAt'] as String? ?? '',
      ),
    );
  }

  final int count;
  final String level;
  final DateTime? lastActivityAt;

  bool isKeptOn(DateTime now) {
    final last = lastActivityAt?.toUtc();
    final today = now.toUtc();
    return last != null &&
        last.year == today.year &&
        last.month == today.month &&
        last.day == today.day;
  }

  @override
  List<Object?> get props => [count, level, lastActivityAt];
}
