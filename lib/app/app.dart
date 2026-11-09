import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import '../config/env/env.dart';
import '../core/di/locator.dart';
import '../core/errors/failure.dart';
import '../core/navigation/navigator_key.dart';
import '../core/network/session_manager.dart';
import '../features/auth/notifier/session_notifier.dart';
import '../features/settings/notifier/settings_notifier.dart';
import '../router/app_router.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_toast.dart';

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
      child: const _TextinMaterialApp(),
    );
  }
}

class _TextinMaterialApp extends ConsumerStatefulWidget {
  const _TextinMaterialApp();

  @override
  ConsumerState<_TextinMaterialApp> createState() => _TextinMaterialAppState();
}

class _TextinMaterialAppState extends ConsumerState<_TextinMaterialApp> {
  @override
  void initState() {
    super.initState();
    locator<SessionManager>().onSessionExpired = _onSessionExpired;
  }

  @override
  void dispose() {
    locator<SessionManager>().onSessionExpired = null;
    super.dispose();
  }

  Future<void> _onSessionExpired() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    ref.read(currentUserProvider.notifier).state = null;
    AppToast.error('Signed out', const SessionExpiredFailure().message);
    rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRouter.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(appThemeProvider).mode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.launch,
    );
  }
}
