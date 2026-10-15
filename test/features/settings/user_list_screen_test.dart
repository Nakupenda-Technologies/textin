import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/features/settings/data_source/settings_remote_data_source.dart';
import 'package:textin/features/settings/models/listed_user.dart';
import 'package:textin/features/settings/presentation/pages/user_list_screen.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repository;

  setUp(() {
    repository = FakeSettingsRepository()
      ..listedUsers = const [
        ListedUser(id: 'u2', displayName: 'Chidi Okafor', username: 'chidi'),
      ];
    locator.registerSingleton<SettingsRepository>(repository);
  });

  tearDown(() => locator.unregister<SettingsRepository>());

  testWidgets('unblocking removes the user from the list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: UserListScreen(kind: UserListKind.blocked)),
    );
    await tester.pump();

    expect(find.text('Chidi Okafor'), findsOneWidget);

    await tester.tap(find.text('Unblock'));
    await tester.pump();

    expect(repository.removedUsers, [(UserListKind.blocked, 'u2')]);
    expect(find.text("You haven't blocked anyone"), findsOneWidget);
  });
}
