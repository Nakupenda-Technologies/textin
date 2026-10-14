import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/navigation/navigator_key.dart';
import 'package:textin/shared/widgets/app_toast.dart';

void main() {
  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(navigatorKey: rootNavigatorKey, home: const Scaffold()),
  );

  testWidgets('a new toast replaces the visible one and auto dismisses', (
    tester,
  ) async {
    await pumpHost(tester);

    AppToast.show('Copied');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Copied'), findsOneWidget);

    AppToast.error('Sign in failed', 'Check your password and try again.');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Copied'), findsNothing);
    expect(find.text('Sign in failed'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Sign in failed'), findsNothing);
  });

  testWidgets('failures are shown with a readable message', (tester) async {
    await pumpHost(tester);

    AppToast.failure('Sign in failed', const NetworkFailure());
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text("You're offline. Check your connection and try again."),
      findsOneWidget,
    );
    AppToast.dismiss();
  });
}
