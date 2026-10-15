import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/user_profile/models/user_profile.dart';
import 'package:textin/features/user_profile/presentation/pages/user_profile_screen.dart';
import 'package:textin/features/user_profile/repository/user_profile_repository.dart';

import 'fake_user_profile_repository.dart';

void main() {
  late FakeUserProfileRepository repository;

  setUp(() {
    repository = FakeUserProfileRepository(
      profileResult: const Right(
        UserProfile(
          id: 'u2',
          username: 'ada',
          displayName: 'Ada Obi',
          bio: 'Building things',
        ),
      ),
    );
    locator.registerSingleton<UserProfileRepository>(repository);
  });

  tearDown(() => locator.unregister<UserProfileRepository>());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: UserProfileScreen(userId: 'u2', name: 'Ada'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the profile with its actions', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Ada Obi'), findsOneWidget);
    expect(find.text('@ada'), findsOneWidget);
    expect(find.text('Building things'), findsOneWidget);
    expect(find.textContaining('Follow'), findsNothing);
    expect(find.text('Mute @ada'), findsOneWidget);
    expect(find.text('Block @ada'), findsOneWidget);
  });

  testWidgets('muting updates the action straight away', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Mute @ada'));
    await tester.pump();

    expect(repository.calls, ['mute:u2:true']);
    expect(find.text('Unmute @ada'), findsOneWidget);
  });

  testWidgets('blocking asks for confirmation first', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Block @ada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.calls, isEmpty);

    await tester.tap(find.text('Block @ada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['block:u2:true']);
    expect(find.text('Unblock @ada'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    repository.profileResult = const Left(ServerFailure('User not found'));
    await pumpScreen(tester);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('User not found'), findsOneWidget);

    repository.profileResult = const Right(
      UserProfile(id: 'u2', username: 'ada', displayName: 'Ada Obi'),
    );
    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(find.text('Block @ada'), findsOneWidget);
  });
}
