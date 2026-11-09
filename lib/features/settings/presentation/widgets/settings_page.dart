import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../models/user_settings.dart';
import '../../notifier/settings_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [_Header(title), const SizedBox(height: 16), ...children],
        ),
      ),
    );
  }
}

typedef SettingsRowsBuilder =
    List<Widget> Function(
      BuildContext context,
      UserSettings settings,
      ValueChanged<UserSettings> update,
    );

class LoadedSettingsPage extends ConsumerStatefulWidget {
  const LoadedSettingsPage({
    super.key,
    required this.title,
    required this.builder,
  });

  final String title;
  final SettingsRowsBuilder builder;

  @override
  ConsumerState<LoadedSettingsPage> createState() => _LoadedSettingsPageState();
}

class _LoadedSettingsPageState extends ConsumerState<LoadedSettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsNotifierProvider.notifier).load());
  }

  void _update(UserSettings settings) =>
      ref.read(settingsNotifierProvider.notifier).update(settings);

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsNotifierProvider, (previous, next) {
      final message = next.errorMessage;
      if (next.status == SettingsStatus.loaded &&
          message != null &&
          message != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final state = ref.watch(settingsNotifierProvider);

    return SettingsPage(
      title: widget.title,
      children: switch (state.status) {
        SettingsStatus.loading => const [
          AppShimmer(child: ShimmerBlock(height: 240, radius: 16)),
        ],
        SettingsStatus.error => [
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? 'Settings could not be loaded.',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySecondary,
          ),
          TextButton(
            onPressed: () => ref.read(settingsNotifierProvider.notifier).load(),
            child: const Text('Try again'),
          ),
        ],
        SettingsStatus.loaded => widget.builder(
          context,
          state.settings,
          _update,
        ),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: isDark ? AppTheme.darkSurface : AppTheme.surface,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox.square(
                  dimension: 40,
                  child: Icon(
                    PhosphorIconsBold.arrowLeft,
                    size: 20,
                    color: cs.onSurface,
                    semanticLabel: 'Back',
                  ),
                ),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
