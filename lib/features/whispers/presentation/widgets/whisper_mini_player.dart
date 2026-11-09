import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../notifier/whisper_room_notifier.dart';
import 'whisper_live_room_sheet.dart';

const _rose = Color(0xFFE11D48);

class WhisperMiniPlayerHost extends ConsumerWidget {
  const WhisperMiniPlayerHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(currentWhisperRoomProvider);
    final sheetOpen = ref.watch(whisperRoomSheetOpenProvider);
    if (room == null || sheetOpen) return const SizedBox.shrink();

    final state = ref.watch(whisperRoomNotifierProvider(room));
    final ended = state.status == WhisperRoomStatus.ended;

    return WhisperMiniPlayer(
      avatarUrl: state.roster.host?.avatarUrl ?? room.hostAvatarUrl,
      name: state.roster.host?.name ?? room.hostName,
      subtitle: ended ? 'Ended' : formatListeners(state.roster.listenerCount),
      isLive: !ended,
      onTap: () => openWhisperRoom(context, room),
      // Hosts step out but never leave their own live whisper; they end it
      // from inside the room.
      onClose: room.isHost && !ended
          ? null
          : () => closeWhisperRoom(ProviderScope.containerOf(context)),
    );
  }
}

class WhisperMiniPlayer extends StatelessWidget {
  const WhisperMiniPlayer({
    super.key,
    required this.avatarUrl,
    required this.name,
    required this.subtitle,
    required this.isLive,
    required this.onTap,
    this.onClose,
  });

  final String? avatarUrl;
  final String name;
  final String subtitle;
  final bool isLive;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B0F),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _AvatarSpeaking(avatarUrl: avatarUrl, animate: isLive),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isLive) ...[
                          const SizedBox(width: 5),
                          Text(
                            'speaking...',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: .55),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: .65),
                          ),
                        ),
                        if (isLive) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: _rose,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: .65),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onClose case final close?)
                GestureDetector(
                  onTap: close,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .06),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _rose,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarSpeaking extends StatelessWidget {
  const _AvatarSpeaking({required this.avatarUrl, required this.animate});

  final String? avatarUrl;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _rose, width: 2),
            ),
          ),
          Avatar(imageUrl: avatarUrl, size: 34),
          if (animate) const _MiniEq(),
        ],
      ),
    );
  }
}

class _MiniEq extends StatefulWidget {
  const _MiniEq();

  @override
  State<_MiniEq> createState() => _MiniEqState();
}

class _MiniEqState extends State<_MiniEq> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EqBar(6 + (t * 4)),
            const SizedBox(width: 2),
            _EqBar(12 - (t * 5)),
            const SizedBox(width: 2),
            _EqBar(8 + (t * 3)),
          ],
        );
      },
    );
  }
}

class _EqBar extends StatelessWidget {
  const _EqBar(this.height);

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF22C55E),
      borderRadius: BorderRadius.circular(99),
    ),
  );
}
