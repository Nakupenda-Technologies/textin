import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/settings/models/user_settings.dart';
import 'package:textin/features/settings/notifier/settings_notifier.dart';
import 'package:textin/features/settings/presentation/pages/account_settings_screen.dart';
import 'package:textin/features/settings/presentation/pages/notification_settings_screen.dart';
import 'package:textin/features/settings/presentation/pages/preference_settings_screen.dart';
import 'package:textin/features/settings/presentation/pages/privacy_settings_screen.dart';
import 'package:textin/features/settings/presentation/pages/whisper_settings_screen.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repository;

  setUp(() {
    repository = FakeSettingsRepository();
    locator.registerSingleton<SettingsRepository>(repository);
  });

  tearDown(() => locator.unregister<SettingsRepository>());

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
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
        child: MaterialApp(home: page),
      ),
    );
    await tester.pump();
  }

  testWidgets('account page shows the email and account actions', (
    tester,
  ) async {
    await pumpPage(tester, const AccountSettingsScreen());

    expect(find.text('ada@example.com'), findsOneWidget);
    for (final action in ['Edit', 'Change', 'Deactivate', 'Delete']) {
      expect(find.text(action), findsOneWidget);
    }
  });

  testWidgets('a wrong password keeps the account', (tester) async {
    await pumpPage(tester, const AccountSettingsScreen());

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

  testWidgets('privacy page shows the chosen audiences', (tester) async {
    await pumpPage(tester, const PrivacySettingsScreen());

    expect(find.text('Who can message me'), findsOneWidget);
    expect(find.text('Who can see my post'), findsOneWidget);
    expect(find.text('Blocked Accounts'), findsOneWidget);
    expect(find.text('Muted Accounts'), findsOneWidget);
  });

  testWidgets('toggling a notification saves it', (tester) async {
    await pumpPage(tester, const NotificationSettingsScreen());

    expect(find.byType(Switch), findsNWidgets(4));
    final wasOn = repository.stored.pushNotifications;
    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    expect(repository.stored.pushNotifications, !wasOn);
  });

  testWidgets('preferences page shows language and theme', (tester) async {
    await pumpPage(tester, const PreferenceSettingsScreen());

    expect(find.text('English (US)'), findsOneWidget);
    for (final theme in AppThemePreference.values) {
      expect(find.text(theme.label), findsOneWidget);
    }
  });

  testWidgets('whispers page shows the whisper toggles', (tester) async {
    await pumpPage(tester, const WhisperSettingsScreen());

    expect(find.text('Allow whispers invites'), findsOneWidget);
    expect(find.text('Allow speaker requests'), findsOneWidget);
    expect(find.text('Allow snippet creation from my voice'), findsOneWidget);
  });
}
