import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/texting/models/message.dart';
import 'package:textin/features/texting/presentation/widgets/message_bubble.dart';

void main() {
  Message message({required bool isMe, MessageType type = MessageType.text}) =>
      Message(
        id: 'm1',
        content: 'The vibe feels so organic right now',
        type: type,
        isMe: isMe,
        timestamp: DateTime(2026, 10, 14, 12, 50),
        voiceDuration: const Duration(seconds: 30),
      );

  Future<void> pumpBubble(WidgetTester tester, Message message) =>
      tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MessageBubble(message: message))),
      );

  testWidgets('sent text shows its time and delivery tick', (tester) async {
    await pumpBubble(tester, message(isMe: true));

    expect(find.text('The vibe feels so organic right now'), findsOneWidget);
    expect(find.text('12:50pm'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);
  });

  testWidgets('received text has no delivery tick', (tester) async {
    await pumpBubble(tester, message(isMe: false));

    expect(find.text('12:50pm'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsNothing);
  });

  testWidgets('voice notes show a play button and duration', (tester) async {
    await pumpBubble(tester, message(isMe: false, type: MessageType.voice));

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('The vibe feels so organic right now'), findsNothing);
  });

  testWidgets('long press starts a reply', (tester) async {
    var replied = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message(isMe: false),
            onReply: () => replied = true,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('The vibe feels so organic right now'));
    expect(replied, isTrue);
  });
}
