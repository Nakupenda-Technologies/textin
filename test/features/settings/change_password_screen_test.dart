import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/features/settings/presentation/pages/change_password_screen.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';
import 'package:textin/shared/widgets/app_text_field.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repository;

  setUp(() {
    repository = FakeSettingsRepository();
    locator.registerSingleton<SettingsRepository>(repository);
  });

  tearDown(() => locator.unregister<SettingsRepository>());

  testWidgets('mismatched passwords are not sent', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChangePasswordScreen())),
    );

    Finder field(String label) => find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextField),
    );
    await tester.enterText(field('Current password'), 'oldpass1');
    await tester.enterText(field('New password'), 'newpass12');
    await tester.pump();
    await tester.enterText(field('Confirm new password'), 'newpass13');
    final button = find.widgetWithText(FilledButton, 'Change password');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(repository.passwordChanges, isEmpty);
  });
}
