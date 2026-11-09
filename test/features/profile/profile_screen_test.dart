import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/profile/presentation/pages/profile_screen.dart';

void main() {
  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
  }

  testWidgets('shows the signed-in user and a tile per settings group', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('@adaobi'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    for (final tile in [
      'Edit profile',
      'Account',
      'Privacy',
      'Notifications',
      'Preferences',
      'Whispers',
    ]) {
      expect(find.text(tile), findsOneWidget);
    }
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('the account tile opens the account page', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Delete my account'), findsOneWidget);
  });
}
