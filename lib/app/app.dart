import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env/env.dart';
import '../core/theme/app_theme.dart';
import '../router/app_router.dart';

class TextinApp extends StatelessWidget {
  const TextinApp({
    super.key,
    this.observers = const [],
    this.overrides = const [],
  });

  final List<ProviderObserver> observers;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      observers: observers,
      overrides: overrides,
      child: MaterialApp(
        title: Env.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.inbox,
      ),
    );
  }
}
