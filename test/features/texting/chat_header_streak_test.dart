import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/storage/shared_preferences_store.dart';
import 'package:textin/features/texting/models/api/chat_streak.dart';
import 'package:textin/features/texting/models/conversation.dart';
import 'package:textin/features/texting/notifier/inbox_notifier.dart';
import 'package:textin/features/texting/presentation/pages/texting_chat_screen.dart';
import 'package:textin/features/texting/services/texting_socket_service.dart';
import 'package:textin/services/websocket_service.dart';

import 'inbox_notifier_test.dart' show MockTextingRepository;

class _StreakRepository extends MockTextingRepository {
  _StreakRepository(this.streak);

  final ChatStreak? streak;

  @override
  Future<Either<Failure, ChatStreak?>> fetchStreak(String chatId) async =>
      Right(streak);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesStore.init();
  });

  Future<void> pumpChat(WidgetTester tester, ChatStreak? streak) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          textingRepositoryProvider.overrideWithValue(
            _StreakRepository(streak),
          ),
          textingSocketServiceProvider.overrideWithValue(
            TextingSocketService(WebSocketService()),
          ),
          myUserIdProvider.overrideWithValue('me'),
        ],
        child: const MaterialApp(
          home: TextingChatScreen(
            conversation: Conversation(id: 'chat_1', name: 'Ada Obi'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the streak kept for today', (tester) async {
    await pumpChat(
      tester,
      ChatStreak(count: 12, level: 'silver', lastActivityAt: DateTime.now()),
    );

    expect(find.text('🔥 12'), findsOneWidget);
  });

  testWidgets('warns when the streak still needs a message today', (
    tester,
  ) async {
    await pumpChat(
      tester,
      ChatStreak(
        count: 12,
        level: 'silver',
        lastActivityAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );

    expect(find.text('🔥 12 ⏳'), findsOneWidget);
    expect(
      find.byTooltip('Silver streak · send a message today to keep it'),
      findsOneWidget,
    );
  });

  testWidgets('hides the badge without a streak', (tester) async {
    await pumpChat(tester, null);

    expect(find.textContaining('🔥'), findsNothing);
  });
}
