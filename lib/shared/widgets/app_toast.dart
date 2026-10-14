import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/error_message.dart';
import '../../core/navigation/navigator_key.dart';
import '../theme/app_theme.dart';

enum _ToastKind { info, error }

class AppToast {
  AppToast._();

  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(String message) => _show(
    kind: _ToastKind.info,
    message: message,
    duration: const Duration(milliseconds: 1800),
  );

  static void error(String title, String message) => _show(
    kind: _ToastKind.error,
    title: title,
    message: message,
    duration: const Duration(seconds: 4),
  );

  static void failure(String title, Object? error) =>
      AppToast.error(title, userMessage(error));

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }

  static void _show({
    required _ToastKind kind,
    required String message,
    required Duration duration,
    String? title,
  }) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    dismiss();
    final entry = OverlayEntry(
      builder: (_) => _ToastView(
        kind: kind,
        title: title,
        message: message,
        onDismiss: dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(duration, dismiss);
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.kind,
    required this.message,
    required this.onDismiss,
    this.title,
  });

  final _ToastKind kind;
  final String? title;
  final String message;
  final VoidCallback onDismiss;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  bool get _isError => widget.kind == _ToastKind.error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final background = _isError
        ? (isDark ? AppTheme.darkSurface2 : AppTheme.surface)
        : colors.inverseSurface;
    final foreground = _isError
        ? (isDark ? AppTheme.darkText : AppTheme.title)
        : colors.onInverseSurface;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return Positioned(
      left: 16,
      right: 16,
      top: _isError ? 0 : null,
      bottom: _isError ? null : 0,
      child: SafeArea(
        minimum: EdgeInsets.only(
          top: _isError ? 12 : 0,
          bottom: _isError ? 0 : 24,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, _isError ? -0.4 : 0.4),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: curve,
            child: Dismissible(
              key: const ValueKey('app_toast'),
              direction: _isError ? DismissDirection.up : DismissDirection.down,
              onDismissed: (_) => widget.onDismiss(),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: background,
                  elevation: _isError ? 6 : 0,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isError)
                          const ColoredBox(
                            color: AppTheme.textred,
                            child: SizedBox(width: 4),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _ToastText(
                              title: widget.title,
                              message: widget.message,
                              color: foreground,
                              messageOpacity: _isError ? 0.8 : 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastText extends StatelessWidget {
  const _ToastText({
    required this.title,
    required this.message,
    required this.color,
    required this.messageOpacity,
  });

  final String? title;
  final String message;
  final Color color;
  final double messageOpacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title case final title?) ...[
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          message,
          style: TextStyle(
            color: color.withValues(alpha: messageOpacity),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
