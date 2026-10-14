import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../models/current_item.dart';
import '../../notifier/registration_notifier.dart';
import '../widgets/registration_scaffold.dart';

class PickCurrentsScreen extends ConsumerStatefulWidget {
  const PickCurrentsScreen({super.key});

  @override
  ConsumerState<PickCurrentsScreen> createState() => _PickCurrentsScreenState();
}

class _PickCurrentsScreenState extends ConsumerState<PickCurrentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(registrationNotifierProvider.notifier).loadCurrents(),
    );
  }

  Future<void> _openPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CurrentsPickerSheet(),
    );
  }

  Future<void> _submit() async {
    final outcome = await ref
        .read(registrationNotifierProvider.notifier)
        .completeRegistration();
    if (!mounted || outcome is! RegistrationCompleted) return;
    final firstName = outcome.user.firstName;
    AppToast.show(
      firstName == null
          ? 'Welcome to Textin.'
          : 'Welcome to Textin, $firstName.',
    );
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.inbox, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationNotifierProvider);
    final notifier = ref.read(registrationNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final error = state.errorFor(RegistrationField.currents);
    final selected = [
      for (final current in state.currents)
        if (state.selectedCurrentIds.contains(current.id)) current,
    ];

    return RegistrationScaffold(
      step: 4,
      title: 'Select Your Current',
      subtitle:
          'Choose ${RegistrationNotifier.minCurrents} to ${RegistrationNotifier.maxCurrents} currents you care about',
      action: AppButton(
        label: 'Submit',
        isLoading: state.isSubmitting,
        onPressed: selected.isEmpty ? null : _submit,
      ),
      children: [
        _PickerField(
          isLoading: state.isLoadingCurrents,
          hasError: error != null,
          onTap: state.currentsLoadFailed
              ? notifier.loadCurrents
              : (state.currents.isEmpty ? null : _openPicker),
          label: switch (state) {
            RegistrationState(isLoadingCurrents: true) => 'Loading currents',
            RegistrationState(currentsLoadFailed: true) =>
              "Couldn't load currents. Tap to try again.",
            RegistrationState(currents: []) =>
              'No currents are available right now.',
            _ => 'Select Currents',
          },
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              error,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CountBadge(count: selected.length),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Selected Currents',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected.isNotEmpty)
                    TextButton(
                      onPressed: notifier.clearCurrents,
                      style: TextButton.styleFrom(
                        foregroundColor: onSurface.withValues(alpha: 0.7),
                        textStyle: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (selected.isEmpty)
                Text(
                  'No currents selected yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final current in selected)
                      _SelectedChip(
                        current: current,
                        onRemove: () => notifier.toggleCurrent(current),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.isLoading,
    required this.hasError,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: isDark ? AppTheme.darkSurface : AppTheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: hasError
              ? theme.colorScheme.error
              : (isDark ? AppTheme.darkBorder : AppTheme.btnborder),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: onSurface.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppTheme.textred,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.current, required this.onRemove});

  final CurrentItem current;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkPinkBg : AppTheme.pinkbg,
        border: Border.all(
          color: isDark ? AppTheme.darkPinkBorder : AppTheme.pinkborder,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            current.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          InkResponse(
            onTap: onRemove,
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                semanticLabel: 'Remove ${current.name}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentsPickerSheet extends ConsumerWidget {
  const _CurrentsPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationNotifierProvider);
    final notifier = ref.read(registrationNotifierProvider.notifier);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pick a Current',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${state.selectedCurrentIds.length} of ${RegistrationNotifier.maxCurrents}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: state.currents.length,
              itemBuilder: (context, index) {
                final current = state.currents[index];
                final isSelected = state.selectedCurrentIds.contains(
                  current.id,
                );
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => notifier.toggleCurrent(current),
                  activeColor: AppTheme.textred,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: Text(
                    current.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: switch (current.description) {
                    final description? => Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    null => null,
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
