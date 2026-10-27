import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../notifier/whisper_room_notifier.dart';

const _rose = Color(0xFFE11D48);
const _slate = Color(0xFF64748B);

Future<void> openWhisperRoom(BuildContext context, WhisperRoomArgs args) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final current = container.read(currentWhisperRoomProvider);
  if (current != null && current.whisperId != args.whisperId) {
    closeWhisperRoom(container);
  }
  final room = container.read(currentWhisperRoomProvider) ?? args;
  if (container.read(currentWhisperRoomProvider) == null) {
    container.read(currentWhisperRoomProvider.notifier).state = room;
    container.read(whisperRoomNotifierProvider(room).notifier).enter();
  }

  container.read(whisperRoomSheetOpenProvider.notifier).state = true;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(ctx),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.92,
            child: WhisperLiveRoom(args: room),
          ),
        ),
      ],
    ),
  );
  container.read(whisperRoomSheetOpenProvider.notifier).state = false;
}

void closeWhisperRoom(ProviderContainer container) {
  final room = container.read(currentWhisperRoomProvider);
  if (room != null) container.invalidate(whisperRoomNotifierProvider(room));
  container.read(currentWhisperRoomProvider.notifier).state = null;
}

String formatListeners(int n) {
  if (n >= 1000) {
    final v = n / 1000.0;
    return '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}k Listeners';
  }
  return '$n Listeners';
}

class WhisperLiveRoom extends ConsumerStatefulWidget {
  const WhisperLiveRoom({super.key, required this.args});

  final WhisperRoomArgs args;

  @override
  ConsumerState<WhisperLiveRoom> createState() => _WhisperLiveRoomState();
}

class _WhisperLiveRoomState extends ConsumerState<WhisperLiveRoom> {
  final List<_EmojiParticleEntry> _particles = [];
  final MenuController _emojiMenu = MenuController();
  int _particleKey = 0;

  WhisperRoomArgs get args => widget.args;

  void _launchEmoji(String emoji) {
    final id = _particleKey++;
    final startX = math.Random().nextDouble() * 0.55 + 0.15;
    setState(
      () => _particles.add(
        _EmojiParticleEntry(id: id, emoji: emoji, startX: startX),
      ),
    );
  }

  void _removeParticle(int id) {
    if (mounted) setState(() => _particles.removeWhere((p) => p.id == id));
  }

  void _leave() {
    closeWhisperRoom(ProviderScope.containerOf(context, listen: false));
    Navigator.pop(context);
  }

  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End this whisper?'),
        content: const Text('End this whisper for everyone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _rose),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(whisperRoomNotifierProvider(args).notifier)
        .end();
    if (!mounted) return;
    if (failure != null) {
      AppToast.failure("Couldn't end the whisper", failure);
      return;
    }
    AppToast.show('Your whisper has ended');
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(whisperRoomNotifierProvider(args));
    final notifier = ref.read(whisperRoomNotifierProvider(args).notifier);
    final roster = state.roster;
    final ended = state.status == WhisperRoomStatus.ended;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final muted = cs.onSurface.withValues(alpha: .55);

    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _RoundIconButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: ended ? muted : _rose,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ended ? 'Ended' : 'Live',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatListeners(roster.listenerCount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!ended)
                      _EndOrLeaveButton(
                        isHost: args.isHost,
                        isEnding: state.isEnding,
                        onTap: args.isHost ? _confirmEnd : _leave,
                      ),
                  ],
                ),
              ),
              _AudioStatusBanner(
                status: state.status,
                message: state.errorMessage,
                onRetry: notifier.retry,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    args.title,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hosted by ${roster.host?.name ?? args.hostName}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _SpeakingRingAvatar(
                        size: 130,
                        imageUrl: roster.host?.avatarUrl ?? args.hostAvatarUrl,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        roster.host?.name ?? args.hostName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w300,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            'Listeners',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (roster.listeners.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No listeners yet.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: .45),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((_, i) {
                          final listener = roster.listeners[i];
                          return Column(
                            children: [
                              Avatar(imageUrl: listener.avatarUrl, size: 52),
                              const SizedBox(height: 6),
                              Text(
                                listener.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: cs.onSurface.withValues(alpha: .50),
                                ),
                              ),
                            ],
                          );
                        }, childCount: roster.listeners.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + bottomInset),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  color: cs.onSurface.withValues(alpha: .07),
                  border: Border(
                    top: BorderSide(color: cs.onSurface.withValues(alpha: .06)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 22,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: ended
                    ? _EndedPanel(onClose: _leave)
                    : Row(
                        children: [
                          Expanded(
                            child: args.isHost
                                ? _MicButton(
                                    state: state,
                                    onToggle: notifier.toggleMute,
                                  )
                                : const _ListeningPill(),
                          ),
                          const SizedBox(width: 10),
                          MenuAnchor(
                            controller: _emojiMenu,
                            alignmentOffset: const Offset(-260, -84),
                            style: const MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.transparent,
                              ),
                              shadowColor: WidgetStatePropertyAll(
                                Colors.transparent,
                              ),
                              elevation: WidgetStatePropertyAll(0),
                              padding: WidgetStatePropertyAll(EdgeInsets.zero),
                            ),
                            menuChildren: [
                              _WhisperEmojiStrip(
                                onEmojiTapped: (emoji) {
                                  _emojiMenu.close();
                                  _launchEmoji(emoji);
                                },
                              ),
                            ],
                            builder: (_, controller, _) => _TinyCircleIcon(
                              icon: Icons.emoji_emotions_rounded,
                              onTap: () => controller.isOpen
                                  ? controller.close()
                                  : controller.open(),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final p in _particles)
                    Positioned.fill(
                      child: _FloatingEmojiParticle(
                        key: ValueKey(p.id),
                        emoji: p.emoji,
                        startX: p.startX,
                        onDone: () => _removeParticle(p.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndOrLeaveButton extends StatelessWidget {
  const _EndOrLeaveButton({
    required this.isHost,
    required this.isEnding,
    required this.onTap,
  });

  final bool isHost;
  final bool isEnding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnding ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _rose.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: isEnding
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _rose),
              )
            : Text(
                isHost ? 'End' : 'Leave',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _rose,
                ),
              ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.state, required this.onToggle});

  final WhisperRoomState state;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final blocked = state.micBlocked;
    final muted = state.isMuted || blocked || !state.canSpeak;

    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: blocked
            ? openAppSettings
            : state.canSpeak
            ? onToggle
            : null,
        icon: Icon(
          muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          blocked
              ? 'Mic blocked'
              : state.isMuted
              ? 'Unmute'
              : 'Mute',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: muted ? _slate : _rose,
          disabledBackgroundColor: _slate.withValues(alpha: .45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _ListeningPill extends StatelessWidget {
  const _ListeningPill();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_rounded,
            size: 18,
            color: cs.onSurface.withValues(alpha: .70),
          ),
          const SizedBox(width: 8),
          Text(
            "You're listening",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: cs.onSurface.withValues(alpha: .70),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndedPanel extends StatelessWidget {
  const _EndedPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'This whisper has ended',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: .70),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: _rose,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 14.8,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TinyCircleIcon extends StatelessWidget {
  const _TinyCircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: .06),
            shape: BoxShape.circle,
            border: Border.all(color: cs.onSurface.withValues(alpha: .06)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: cs.onSurface.withValues(alpha: .70),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surface,
            shape: BoxShape.circle,
            border: Border.all(color: cs.onSurface.withValues(alpha: .06)),
          ),
          child: Icon(
            icon,
            size: 22,
            color: cs.onSurface.withValues(alpha: .75),
          ),
        ),
      ),
    );
  }
}

class _SpeakingRingAvatar extends StatelessWidget {
  const _SpeakingRingAvatar({required this.size, this.imageUrl});

  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _DashedCirclePainter(
              color: _rose.withValues(alpha: .45),
              dashCount: 44,
              gapFactor: 0.62,
            ),
          ),
        ),
        SizedBox.square(
          dimension: size - 18,
          child: CustomPaint(
            painter: _DashedCirclePainter(
              color: _rose.withValues(alpha: .45),
              dashCount: 38,
              gapFactor: 0.58,
            ),
          ),
        ),
        Container(
          width: size - 36,
          height: size - 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _rose, width: 4.5),
          ),
        ),
        Avatar(imageUrl: imageUrl, size: size - 54),
        Positioned(
          right: (size * 0.20) - 8,
          bottom: (size * 0.20) - 8,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _rose,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.color,
    this.dashCount = 40,
    this.gapFactor = 0.6,
  });

  final Color color;
  final int dashCount;
  final double gapFactor;

  static const _strokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - _strokeWidth / 2;
    final step = 2 * math.pi / dashCount;
    final dash = step * (1 - gapFactor);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        dash,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color ||
      old.dashCount != dashCount ||
      old.gapFactor != gapFactor;
}

class _AudioStatusBanner extends StatelessWidget {
  const _AudioStatusBanner({
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final WhisperRoomStatus status;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == WhisperRoomStatus.connected ||
        status == WhisperRoomStatus.ended) {
      return const SizedBox.shrink();
    }
    final failed = status == WhisperRoomStatus.failed;
    final label = switch (status) {
      WhisperRoomStatus.joining => 'Connecting audio…',
      WhisperRoomStatus.reconnecting => 'Reconnecting…',
      _ => message ?? 'Audio disconnected',
    };
    final color = failed ? _rose : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (failed)
              Icon(Icons.volume_off_rounded, size: 16, color: color)
            else
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            if (failed)
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmojiParticleEntry {
  _EmojiParticleEntry({
    required this.id,
    required this.emoji,
    required this.startX,
  });

  final int id;
  final String emoji;
  final double startX;
}

class _FloatingEmojiParticle extends StatefulWidget {
  const _FloatingEmojiParticle({
    super.key,
    required this.emoji,
    required this.startX,
    required this.onDone,
  });

  final String emoji;
  final double startX;
  final VoidCallback onDone;

  @override
  State<_FloatingEmojiParticle> createState() => _FloatingEmojiParticleState();
}

class _FloatingEmojiParticleState extends State<_FloatingEmojiParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _curved,
          builder: (_, _) {
            final t = _curved.value;
            final bottom = t * (h + 60) - 30;
            final wiggle = math.sin(t * math.pi * 4) * 14.0;
            final left = (widget.startX * w + wiggle).clamp(4.0, w - 44.0);
            final opacity = t < 0.55
                ? 1.0
                : (1.0 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  bottom: bottom,
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

const _reactionEmojis = [
  '💗',
  '👍',
  '🎉',
  '👏',
  '😂',
  '😮',
  '😢',
  '🤔',
  '👎',
  '🔥',
];

class _WhisperEmojiStrip extends StatelessWidget {
  const _WhisperEmojiStrip({required this.onEmojiTapped});

  final ValueChanged<String> onEmojiTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _reactionEmojis.length; i++) ...[
            GestureDetector(
              onTap: () => onEmojiTapped(_reactionEmojis[i]),
              child: Text(
                _reactionEmojis[i],
                style: const TextStyle(fontSize: 28),
              ),
            ),
            if (i < _reactionEmojis.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
