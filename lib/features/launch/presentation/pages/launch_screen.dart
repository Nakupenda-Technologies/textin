import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_message.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/storage/shared_pref_keys.dart';
import '../../../../core/storage/shared_preferences_store.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/notifier/session_notifier.dart';

class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  static const Duration displayDuration = Duration(milliseconds: 1600);

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen>
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

  String? _connectionError;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final destination = _resolveDestination();
    try {
      await _controller.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    _handleDestination(await destination);
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    final destination = await _resolveDestination();
    if (!mounted) return;
    setState(() => _isRetrying = false);
    _handleDestination(destination);
  }

  void _handleDestination(Either<Failure, String> destination) {
    if (!mounted) return;
    destination.fold(
      (failure) => setState(() => _connectionError = userMessage(failure)),
      (route) => Navigator.of(context).pushReplacementNamed(route),
    );
  }

  Future<Either<Failure, String>> _resolveDestination() async {
    final repository = ref.read(authRepositoryProvider);

    if (repository.pendingProcessId != null) {
      final resumed = await repository.resumeRegistration();
      final failure = resumed.fold<Failure?>((failure) => failure, (_) => null);
      if (failure is SessionExpiredFailure) return const Right(AppRouter.login);
      if (failure != null) return Left(failure);
      final step = resumed.getOrElse(() => null);
      if (step != null) {
        return Right(AppRouter.routeForRegistrationStep(step));
      }
    }

    if (repository.hasSession) {
      if (repository.cachedUser != null) return const Right(AppRouter.inbox);

      final refreshed = await repository.refreshUser();
      return refreshed.fold<Either<Failure, String>>(
        (failure) => failure is SessionExpiredFailure
            ? const Right(AppRouter.login)
            : Left(failure),
        (user) {
          if (mounted) ref.read(currentUserProvider.notifier).state = user;
          return const Right(AppRouter.inbox);
        },
      );
    }

    final onboardingSeen =
        SharedPreferencesStore.getBool(SharedPrefKeys.onboardingSeen) ?? false;
    return Right(onboardingSeen ? AppRouter.login : AppRouter.onboarding);
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
              minimum: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: switch (_connectionError) {
                final message? => _ConnectionRetryPanel(
                  message: message,
                  isRetrying: _isRetrying,
                  onRetry: _retry,
                ),
                null => FadeTransition(
                  opacity: _wordmarkOpacity,
                  child: Image.asset(
                    isDark
                        ? 'assets/images/textin_wordmark_dark.png'
                        : 'assets/images/textin_wordmark.png',
                    height: 28,
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionRetryPanel extends StatelessWidget {
  const _ConnectionRetryPanel({
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Can't connect right now",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Try again',
          isLoading: isRetrying,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
