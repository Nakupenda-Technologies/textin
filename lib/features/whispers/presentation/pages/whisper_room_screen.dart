import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../notifier/whisper_room_notifier.dart';

class WhisperRoomScreen extends ConsumerStatefulWidget {
  const WhisperRoomScreen({super.key, required this.args});

  final WhisperRoomArgs args;

  @override
  ConsumerState<WhisperRoomScreen> createState() => _WhisperRoomScreenState();
}

class _WhisperRoomScreenState extends ConsumerState<WhisperRoomScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(whisperRoomNotifierProvider(widget.args).notifier).enter(),
    );
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this whisper?'),
        content: const Text('Everyone listening will be disconnected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(whisperRoomNotifierProvider(widget.args).notifier)
        .end();
    if (failure != null) AppToast.failure("Couldn't end the whisper", failure);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final state = ref.watch(whisperRoomNotifierProvider(args));
    final notifier = ref.read(whisperRoomNotifierProvider(args).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final ended = state.status == WhisperRoomStatus.ended;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      appBar: AppBar(title: const Text('Whisper')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                child: Text(
                  args.hostName.isNotEmpty
                      ? args.hostName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                args.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                args.isHost ? 'You are hosting' : 'Hosted by ${args.hostName}',
                style: AppTextStyle.bodySecondary,
              ),
              const SizedBox(height: 16),
              _StatusLine(state: state, onRetry: notifier.retry),
              const Spacer(),
              if (ended)
                AppButton(
                  label: 'Close',
                  onPressed: () => Navigator.pop(context),
                )
              else if (args.isHost) ...[
                if (state.micBlocked)
                  const _MicBlockedNotice()
                else
                  _MicButton(
                    enabled: state.canSpeak,
                    muted: state.isMuted,
                    onTap: notifier.toggleMute,
                  ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'End whisper',
                  variant: AppButtonVariant.outline,
                  isLoading: state.isEnding,
                  onPressed: state.isEnding ? null : _confirmEnd,
                ),
              ] else
                AppButton(
                  label: 'Leave',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state, required this.onRetry});

  final WhisperRoomState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state.status) {
      WhisperRoomStatus.joining => ('Connecting…', AppTheme.textingTimestamp),
      WhisperRoomStatus.connected => ('Live', AppTheme.red),
      WhisperRoomStatus.reconnecting => (
        'Reconnecting…',
        AppTheme.textingTimestamp,
      ),
      WhisperRoomStatus.failed => (
        state.errorMessage ?? "Live audio couldn't connect.",
        AppTheme.textingTimestamp,
      ),
      WhisperRoomStatus.ended => (
        'This whisper has ended',
        AppTheme.textingTimestamp,
      ),
    };

    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (state.status == WhisperRoomStatus.failed)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.enabled,
    required this.muted,
    required this.onTap,
  });

  final bool enabled;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final live = enabled && !muted;

    return Column(
      children: [
        Material(
          shape: const CircleBorder(),
          color: live ? AppTheme.textred : AppTheme.grayBg,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: SizedBox.square(
              dimension: 76,
              child: Icon(
                live ? Icons.mic_rounded : Icons.mic_off_rounded,
                size: 34,
                color: live ? Colors.white : AppTheme.textingTimestamp,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          !enabled
              ? 'Waiting for audio…'
              : muted
              ? 'Muted · tap to speak'
              : 'You are live · tap to mute',
          style: AppTextStyle.bodySecondary.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _MicBlockedNotice extends StatelessWidget {
  const _MicBlockedNotice();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Microphone access is off, so nobody can hear you.',
          textAlign: TextAlign.center,
          style: AppTextStyle.bodySecondary,
        ),
        TextButton(
          onPressed: openAppSettings,
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
