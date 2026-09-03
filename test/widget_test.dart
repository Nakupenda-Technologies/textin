import 'package:flutter_test/flutter_test.dart';
import 'package:textin/app/app.dart';
import 'package:textin/config/env/env.dart';
import 'package:textin/core/di/locator.dart';
import 'package:textin/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.init();
    await locator.reset();
    await setupLocator();
    Env.setFlavor(Flavor.dev);
  });

  tearDown(() async {
    await locator.reset();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TextinApp());
    await tester.pumpAndSettle();

    expect(find.text('Textin Dev'), findsOneWidget);
    expect(find.text('DEV'), findsOneWidget);
  });
}
