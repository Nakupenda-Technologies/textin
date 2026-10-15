import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, outline }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPrimary = variant == AppButtonVariant.primary;
    final enabledForeground = isPrimary
        ? Colors.white
        : (isDark ? AppTheme.darkText : AppTheme.header);

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!isPrimary) return Colors.transparent;
        if (isLoading) return AppTheme.textred;
        if (states.contains(WidgetState.disabled)) {
          return isDark ? AppTheme.darkPostBtn : AppTheme.redbg;
        }
        return AppTheme.textred;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled) && !isLoading) {
          return isDark
              ? AppTheme.darkMuted
              : (isPrimary ? AppTheme.pillRed : AppTheme.grey);
        }
        return enabledForeground;
      }),
      side: isPrimary
          ? null
          : WidgetStatePropertyAll(
              BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.btnborder,
              ),
            ),
    );

    final labelText = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: isLoading
          ? Shimmer.fromColors(
              key: const ValueKey('loading'),
              baseColor: enabledForeground.withValues(alpha: 0.45),
              highlightColor: enabledForeground,
              child: labelText,
            )
          : KeyedSubtree(key: const ValueKey('label'), child: labelText),
    );

    return Semantics(
      button: true,
      label: isLoading ? '$label, loading' : null,
      child: isPrimary
          ? FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: style,
              child: child,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: style,
              child: child,
            ),
    );
  }
}
