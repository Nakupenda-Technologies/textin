import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/chat_customization.dart';
import '../../models/message.dart';
import 'mood_palette.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onReply,
    this.customization = const ChatCustomization(),
  });

  final Message message;
  final VoidCallback? onReply;
  final ChatCustomization customization;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggleVoicePlayback() async {
    if (widget.message.mediaUrl == null || widget.message.mediaUrl!.isEmpty) {
      return;
    }

    if (_player == null) {
      _player = AudioPlayer();
      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying =
                state.playing &&
                state.processingState != ProcessingState.completed;
            if (state.processingState == ProcessingState.completed) {
              _position = Duration.zero;
            }
          });
        }
      });
      _player!.positionStream.listen((pos) {
        if (mounted) {
          setState(() => _position = pos);
        }
      });
      await _player!.setUrl(widget.message.mediaUrl!);
    }

    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  double get _playbackProgress {
    final total = widget.message.voiceDuration?.inMilliseconds ?? 0;
    if (total <= 0) return 0;
    return (_position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final palette = MoodPalette.of(widget.customization.mood);

    final bubbleBg = isMe
        ? palette.sentBg
        : (isDark ? AppTheme.darkTextingReceivedBubble : palette.receivedBg);
    final fg = isMe
        ? palette.sentFg
        : (isDark ? cs.onSurface : palette.receivedFg);
    final border = isMe
        ? palette.sentBorder
        : (isDark ? AppTheme.darkPinkBorder : palette.receivedBorder);

    return GestureDetector(
      onLongPress: widget.onReply,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: bubbleRadius(
                  widget.customization.bubbleStyle,
                  isMe: isMe,
                ),
                border: border == null
                    ? null
                    : Border.all(width: 0.5, color: border),
              ),
              padding: widget.message.type == MessageType.voice
                  ? const EdgeInsets.fromLTRB(8, 8, 16, 8)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.message.type == MessageType.image &&
                      widget.message.mediaUrl != null)
                    _buildImageMessage(widget.message.mediaUrl!),
                  if (widget.message.type == MessageType.voice)
                    _buildVoiceMessage(fg, isMe ? bubbleBg : Colors.white),
                  if (widget.message.type != MessageType.voice &&
                      widget.message.content.isNotEmpty)
                    Text(
                      widget.message.content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                    color: AppTheme.textingTimestamp,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIndicator(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: CachedNetworkImage(
        imageUrl: url,
        placeholder: (ctx, _) => Container(
          height: 180,
          color: Colors.black12,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (ctx, _, _) => Container(
          height: 120,
          color: Colors.black12,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildVoiceMessage(Color fg, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleVoicePlayback,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _Waveform(
          seed: widget.message.id.hashCode,
          progress: _playbackProgress,
          color: fg,
        ),
        const SizedBox(width: 12),
        Text(
          widget.message.formattedDuration,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: fg.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    switch (widget.message.status) {
      case MessageStatus.pending:
        return const Icon(
          Icons.access_time,
          size: 12,
          color: AppTheme.textingTimestamp,
        );
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: AppTheme.red);
      case MessageStatus.sent:
        return Icon(
          widget.message.isRead ? Icons.done_all : Icons.done,
          size: 14,
          color: AppTheme.textingTimestamp,
        );
    }
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({
    required this.seed,
    required this.progress,
    required this.color,
  });

  static const _barCount = 28;

  final int seed;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final random = Random(seed);
    final played = (progress * _barCount).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _barCount; i++)
          Container(
            width: 2,
            height: 4 + random.nextDouble() * 20,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: progress > 0 && i >= played
                  ? color.withValues(alpha: 0.45)
                  : color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}
