import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/app/app.dart';
import 'package:textin/config/env/env.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/core/storage/session_store.dart';
import 'package:textin/core/storage/shared_pref_keys.dart';
import 'package:textin/features/auth/data_source/auth_remote_data_source.dart';
import 'package:textin/features/auth/presentation/pages/create_account_screen.dart';
import 'package:textin/features/auth/presentation/pages/login_screen.dart';
import 'package:textin/features/launch/presentation/pages/launch_screen.dart';
import 'package:textin/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:textin/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/fake_auth_remote_data_source.dart';

Future<FakeAuthRemoteDataSource> _bootstrap({
  Map<String, Object> prefs = const {},
  Map<String, String> secure = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  FlutterSecureStorage.setMockInitialValues(Map.of(secure));
  await LocalStorageService.init();
  await locator.reset();
  await setupLocator();
  await locator<SessionStore>().load();
  final remote = FakeAuthRemoteDataSource();
  await locator.unregister<AuthRemoteDataSource>();
  locator.registerSingleton<AuthRemoteDataSource>(remote);
  Env.setFlavor(Flavor.dev);
  return remote;
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _settleFrames(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

FilledButton _button(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
);

void main() {
  tearDown(() async {
    await locator.reset();
  });

  testWidgets('first launch shows onboarding after the loading screen', (
    tester,
  ) async {
    await _bootstrap();
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());

    expect(find.byType(LaunchScreen), findsOneWidget);

    await _settleFrames(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Talk closer'), findsOneWidget);
  });

  testWidgets('finishing onboarding opens sign in and remembers it', (
    tester,
  ) async {
    await _bootstrap();
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());
    await _settleFrames(tester);

    for (final _ in [1, 2]) {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Keep the spark'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await _settleFrames(tester, 2);

    expect(find.byType(LoginScreen), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SharedPrefKeys.onboardingSeen), isTrue);
  });

  testWidgets('returning signed out users land on sign in', (tester) async {
    await _bootstrap(prefs: {SharedPrefKeys.onboardingSeen: true});
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());
    await _settleFrames(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Exhale'), findsOneWidget);
  });

  testWidgets('signed in users go straight to their inbox', (tester) async {
    await _bootstrap(
      prefs: {
        SharedPrefKeys.onboardingSeen: true,
        SharedPrefKeys.cachedUser: jsonEncode(
          FakeAuthRemoteDataSource.user.toJson(),
        ),
      },
      secure: {'session_access_token': 'token'},
    );
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());
    await _settleFrames(tester);

    expect(find.text('Textin Dev'), findsOneWidget);
  });

  testWidgets('login stays disabled until both fields are filled', (
    tester,
  ) async {
    await _bootstrap(prefs: {SharedPrefKeys.onboardingSeen: true});
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());
    await _settleFrames(tester);

    expect(_button(tester, 'Login').onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), 'slim');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.pump();
    expect(_button(tester, 'Login').onPressed, isNotNull);

    await tester.tap(find.text('Login'));
    await _settleFrames(tester, 3);

    expect(find.text('Textin Dev'), findsOneWidget);
  });

  testWidgets('the sign up link opens the create profile step', (tester) async {
    await _bootstrap(prefs: {SharedPrefKeys.onboardingSeen: true});
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());
    await _settleFrames(tester);

    await tester.tapOnText(find.textRange.ofSubstring('Sign Up'));
    await _settleFrames(tester, 2);

    expect(find.byType(CreateAccountScreen), findsOneWidget);
    expect(find.text('Create Profile'), findsOneWidget);
  });
}
