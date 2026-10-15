import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/profile/presentation/pages/profile_screen.dart';
import 'package:textin/features/settings/notifier/settings_notifier.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  testWidgets('shows the signed-in user', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith(
            (ref) => SettingsNotifier(
              FakeSettingsRepository(),
              onThemeChanged: (_) {},
            ),
          ),
          currentUserProvider.overrideWith(
            (ref) => const AuthUser(
              id: 'u1',
              username: 'adaobi',
              firstName: 'Ada',
              lastName: 'Obi',
              email: 'ada@example.com',
            ),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('@adaobi'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('Who can message me'), findsOneWidget);
    expect(find.text('Push notifications'), findsOneWidget);
  });

  testWidgets('a wrong password keeps the account', (tester) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repository = FakeSettingsRepository();
    locator.registerSingleton<SettingsRepository>(repository);
    addTearDown(() => locator.unregister<SettingsRepository>());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsNotifierProvider.overrideWith(
            (ref) => SettingsNotifier(repository, onThemeChanged: (_) {}),
          ),
          currentUserProvider.overrideWith(
            (ref) => const AuthUser(id: 'u1', username: 'adaobi'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'wrong-pass');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletePasswords, ['wrong-pass']);
    expect(find.text('Invalid password'), findsOneWidget);
  });
}
