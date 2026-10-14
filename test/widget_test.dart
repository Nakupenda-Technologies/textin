import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/app/app.dart';
import 'package:textin/config/env/env.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/core/storage/shared_pref_keys.dart';
import 'package:textin/features/launch/presentation/pages/launch_screen.dart';
import 'package:textin/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:textin/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _bootstrap(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  await LocalStorageService.init();
  await locator.reset();
  await setupLocator();
  Env.setFlavor(Flavor.dev);
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pastLaunch(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  tearDown(() async {
    await locator.reset();
  });

  testWidgets('first launch shows onboarding after the loading screen', (
    tester,
  ) async {
    await _bootstrap({});
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());

    expect(find.byType(LaunchScreen), findsOneWidget);

    await _pastLaunch(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Talk closer'), findsOneWidget);
  });

  testWidgets('finishing onboarding opens the inbox and remembers it', (
    tester,
  ) async {
    await _bootstrap({});
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());
    await _pastLaunch(tester);

    for (final _ in [1, 2]) {
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Keep the spark'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Textin Dev'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SharedPrefKeys.onboardingSeen), isTrue);
  });

  testWidgets('returning users skip onboarding', (tester) async {
    await _bootstrap({SharedPrefKeys.onboardingSeen: true});
    _usePhoneViewport(tester);
    await tester.pumpWidget(const TextinApp());
    await _pastLaunch(tester);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Textin Dev'), findsOneWidget);
    expect(find.text('DEV'), findsOneWidget);
  });
}
