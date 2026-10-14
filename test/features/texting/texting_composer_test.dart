import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/texting/presentation/widgets/texting_composer.dart';

void main() {
  testWidgets('shows the mic until a message is typed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextingComposer(
            onSendText: (_) {},
            onSendImage: (_) {},
            onSendVoice: (_, _) {},
            onTyping: (_) {},
            onOpenAura: () {},
          ),
        ),
      ),
    );

    bool showsSend() => tester
        .widgetList<SvgPicture>(find.byType(SvgPicture))
        .any((svg) => svg.bytesLoader.toString().contains('send_icon'));

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.text('Type something lovely...'), findsOneWidget);
    expect(showsSend(), isFalse);

    await tester.enterText(find.byType(TextField), 'Hiii');
    await tester.pump();

    expect(find.byIcon(Icons.mic_rounded), findsNothing);
    expect(showsSend(), isTrue);
  });
}
