import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../models/my_whisper.dart';
import '../../notifier/my_whispers_notifier.dart';
import '../../notifier/whispers_notifier.dart';

final _scheduleFormat = DateFormat('EEE, MMM d · h:mm a');

class MyWhispersList extends ConsumerWidget {
  const MyWhispersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myWhispersNotifierProvider);
    final notifier = ref.read(myWhispersNotifierProvider.notifier);

    if (state.status == WhispersStatus.loading && state.whispers.isEmpty) {
      return const ShimmerList();
    }

    if (state.status == WhispersStatus.error && state.whispers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? 'Your whispers could not be loaded.',
                textAlign: TextAlign.center,
                style: AppTextStyle.bodySecondary,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: notifier.load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.whispers.isEmpty) {
      return Center(
        child: Text(
          "You haven't created a whisper yet 🎙️",
          style: AppTextStyle.bodySecondary,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        itemCount: state.whispers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) =>
            _MyWhisperCard(whisper: state.whispers[index]),
      ),
    );
  }
}

class _MyWhisperCard extends StatelessWidget {
  const _MyWhisperCard({required this.whisper});

  final MyWhisper whisper;

  String get _statusLabel => switch (whisper.status) {
    WhisperStatus.draft => 'Draft',
    WhisperStatus.scheduled => switch (whisper.scheduledAt) {
      final at? => 'Scheduled · ${_scheduleFormat.format(at)}',
      null => 'Scheduled',
    },
    WhisperStatus.live => 'Live now',
    WhisperStatus.ended => 'Ended',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final isLive = whisper.status == WhisperStatus.live;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  whisper.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isLive ? AppTheme.red : AppTheme.textingTimestamp,
                  ),
                ),
              ],
            ),
          ),
          if (whisper.isPrivate)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppTheme.textingTimestamp,
              ),
            ),
        ],
      ),
    );
  }
}
