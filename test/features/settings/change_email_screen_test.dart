import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/features/settings/presentation/pages/change_email_screen.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repository;

  setUp(() {
    repository = FakeSettingsRepository();
    locator.registerSingleton<SettingsRepository>(repository);
  });

  tearDown(() => locator.unregister<SettingsRepository>());

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: ChangeEmailScreen())),
  );

  testWidgets('an invalid email is rejected before sending', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('Send code'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(repository.emailChangeRequests, isEmpty);
  });

  testWidgets('sending the code asks for it next', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.tap(find.text('Send code'));
    await tester.pump();

    expect(repository.emailChangeRequests, ['new@example.com']);
    expect(
      find.text('Enter the 6-digit code we sent to new@example.com.'),
      findsOneWidget,
    );
  });
}
