import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/settings/notifier/settings_notifier.dart';
import 'package:textin/features/settings/presentation/pages/settings_screen.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repository;

  setUp(() {
    repository = FakeSettingsRepository();
    locator.registerSingleton<SettingsRepository>(repository);
  });

  tearDown(() => locator.unregister<SettingsRepository>());

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith(
            (ref) => SettingsNotifier(repository, onThemeChanged: (_) {}),
          ),
          currentUserProvider.overrideWith(
            (ref) => const AuthUser(id: 'u1', email: 'ada@example.com'),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the designed sections', (tester) async {
    await pumpSettings(tester);

    for (final heading in [
      'Account',
      'Privacy',
      'Notification',
      'Preferences',
      'More',
      'Content & Discovery',
    ]) {
      expect(find.text(heading), findsOneWidget);
    }
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('English (US)'), findsOneWidget);
    expect(find.text('Who can see my post'), findsOneWidget);
    expect(find.text('Allow my content in Currents'), findsOneWidget);
  });

  testWidgets('search narrows the list to matching settings', (tester) async {
    await pumpSettings(tester);

    await tester.enterText(find.byType(TextField), 'muted');
    await tester.pump();

    expect(find.text('Muted Accounts'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Push notifications'), findsNothing);
    expect(find.text('Account'), findsNothing);
  });

  testWidgets('a wrong password keeps the account', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'wrong-pass',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.deletePasswords, ['wrong-pass']);
    expect(find.text('Invalid password'), findsOneWidget);
  });
}
