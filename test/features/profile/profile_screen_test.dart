import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/notifier/session_notifier.dart';
import 'package:textin/features/profile/presentation/pages/profile_screen.dart';

void main() {
  testWidgets('shows the signed-in user and links to settings', (tester) async {
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

    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('@adaobi'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}
