import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';

class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    this.step,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.children,
    this.footer,
    this.canGoBack = false,
  });

  static const int totalSteps = 4;

  final int? step;
  final String title;
  final String subtitle;
  final Widget action;
  final List<Widget> children;
  final Widget? footer;
  final bool canGoBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (canGoBack)
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: TextButton.styleFrom(
                            foregroundColor: onSurface,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                          ),
                          label: const Text('Back'),
                        ),
                      const Spacer(),
                      if (step case final step?) _StepRing(step: step),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          color: isDark ? AppTheme.darkTitle : AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ...children,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    action,
                    if (footer case final footer?) ...[
                      const SizedBox(height: 16),
                      footer,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRing extends StatelessWidget {
  const _StepRing({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Step $step of ${AuthFormScaffold.totalSteps}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: step / AuthFormScaffold.totalSteps),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                  color: AppTheme.textingSendBtn,
                  backgroundColor: isDark
                      ? AppTheme.darkDivider
                      : AppTheme.greyFill,
                ),
              ),
            ),
            Text(
              '$step',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textingSendBtn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
