import 'package:flutter/material.dart';

import '../../../../core/storage/shared_pref_keys.dart';
import '../../../../core/storage/shared_preferences_store.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  static const Duration displayDuration = Duration(milliseconds: 1600);

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LaunchScreen.displayDuration,
  );

  late final Animation<double> _pulse = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.04), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _wordmarkOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(_continue);
  }

  void _continue() {
    if (!mounted) return;
    final onboardingSeen =
        SharedPreferencesStore.getBool(SharedPrefKeys.onboardingSeen) ?? false;
    Navigator.of(context).pushReplacementNamed(
      onboardingSeen ? AppRouter.inbox : AppRouter.onboarding,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surface,
      body: Stack(
        children: [
          Center(
            child: ScaleTransition(
              scale: _pulse,
              child: Image.asset('assets/images/textin_logo.png', width: 270),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 32),
              child: FadeTransition(
                opacity: _wordmarkOpacity,
                child: Image.asset(
                  isDark
                      ? 'assets/images/textin_wordmark_dark.png'
                      : 'assets/images/textin_wordmark.png',
                  height: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
