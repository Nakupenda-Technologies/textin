import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'bootstrap.dart';
import 'core/di/locator.dart';
import 'services/connectivity_service.dart';
import 'services/local_storage_service.dart';

Future<void> mainCommon() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, st) {
    developer.log(
      'setPreferredOrientations failed: $e',
      name: 'Textin',
      stackTrace: st,
    );
  }

  try {
    await LocalStorageService.init();
  } catch (e, st) {
    developer.log(
      'LocalStorageService.init failed: $e',
      name: 'Textin',
      stackTrace: st,
    );
  }

  try {
    await ConnectivityService().initialize();
  } catch (e, st) {
    developer.log(
      'ConnectivityService.initialize failed: $e',
      name: 'Textin',
      stackTrace: st,
    );
  }

  await setupLocator();

  runApp(
    const TextinApp(
      observers: [AppProviderObserver()],
    ),
  );
}
