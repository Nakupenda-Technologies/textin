import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env/env.dart';
import '../router/app_router.dart';
import '../shared/theme/app_theme.dart';

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
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.inbox,
      ),
    );
  }
}
