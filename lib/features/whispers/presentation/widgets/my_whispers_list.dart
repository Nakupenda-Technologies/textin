import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../models/my_whisper.dart';
import '../../notifier/my_whispers_notifier.dart';
import '../../notifier/whisper_room_notifier.dart';
import '../../notifier/whispers_notifier.dart';
import '../pages/whisper_room_screen.dart';

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

class _MyWhisperCard extends ConsumerStatefulWidget {
  const _MyWhisperCard({required this.whisper});

  final MyWhisper whisper;

  @override
  ConsumerState<_MyWhisperCard> createState() => _MyWhisperCardState();
}

class _MyWhisperCardState extends ConsumerState<_MyWhisperCard> {
  bool _isStarting = false;

  MyWhisper get whisper => widget.whisper;

  String get _statusLabel => switch (whisper.status) {
    WhisperStatus.draft => 'Draft',
    WhisperStatus.scheduled => switch (whisper.scheduledAt) {
      final at? => 'Scheduled · ${_scheduleFormat.format(at)}',
      null => 'Scheduled',
    },
    WhisperStatus.live => 'Live now',
    WhisperStatus.ended => 'Ended',
  };

  Future<void> _goLive() async {
    final notifier = ref.read(myWhispersNotifierProvider.notifier);
    if (whisper.status != WhisperStatus.live) {
      setState(() => _isStarting = true);
      final failure = await notifier.start(whisper.id);
      if (!mounted) return;
      setState(() => _isStarting = false);
      if (failure != null) {
        AppToast.failure("Couldn't go live", failure);
        return;
      }
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WhisperRoomScreen(
          args: WhisperRoomArgs(
            whisperId: whisper.id,
            title: whisper.title,
            hostName: ref.read(currentUserProvider)?.displayName ?? '',
            isHost: true,
          ),
        ),
      ),
    );
    notifier.load();
  }

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
          if (whisper.status != WhisperStatus.ended) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isStarting ? null : _goLive,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.textred,
                foregroundColor: Colors.white,
                minimumSize: const Size(84, 34),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: _isStarting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isLive ? 'Rejoin' : 'Go live'),
            ),
          ],
        ],
      ),
    );
  }
}
