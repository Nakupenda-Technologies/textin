import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/profile/presentation/pages/profile_screen.dart';
import 'package:textin/features/settings/notifier/settings_notifier.dart';

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
}
