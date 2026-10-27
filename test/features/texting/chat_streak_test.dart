import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/texting/models/api/chat_streak.dart';

void main() {
  test('reads the backend streak score as a whole count', () {
    final streak = ChatStreak.fromJson({
      'userId': 'me',
      'peerUserId': 'u2',
      'level': 'silver',
      'value': 10.87,
      'lastActivityAt': '2026-10-27T08:00:00.000Z',
    });

    expect(streak.count, 10);
    expect(streak.level, 'silver');
  });

  test('is kept only when there was activity on the same UTC day', () {
    final streak = ChatStreak(
      count: 3,
      level: 'bronze',
      lastActivityAt: DateTime.utc(2026, 10, 27, 8),
    );

    expect(streak.isKeptOn(DateTime.utc(2026, 10, 27, 23, 59)), isTrue);
    expect(streak.isKeptOn(DateTime.utc(2026, 10, 28, 0, 1)), isFalse);
  });
}
