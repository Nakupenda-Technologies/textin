import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/message.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onReply,
  });

  final Message message;
  final VoidCallback? onReply;

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
            _isPlaying = state.playing &&
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

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final bubbleBg = isMe
        ? AppTheme.textingSentBubble
        : (isDark ? AppTheme.darkTextingReceivedBubble : Colors.white);
    final textFg = isMe ? const Color(0xFF163917) : cs.onSurface;
    final timeFg = isMe
        ? const Color(0xFF163917).withValues(alpha: 0.65)
        : cs.onSurface.withValues(alpha: 0.55);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: isDark
                      ? AppTheme.darkBorder
                      : const Color(0xFFDDDEE2),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (widget.message.type == MessageType.image &&
                widget.message.mediaUrl != null)
              _buildImageMessage(widget.message.mediaUrl!),
            if (widget.message.type == MessageType.voice)
              _buildVoiceMessage(isMe),
            if (widget.message.content.isNotEmpty)
              Text(
                widget.message.content,
                style: AppTextStyle.body.copyWith(
                  color: textFg,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.formattedTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: timeFg,
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
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildVoiceMessage(bool isMe) {
    final durationText = widget.message.formattedDuration;
    final fg = isMe ? const Color(0xFF163917) : Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: fg,
            size: 32,
          ),
          onPressed: _toggleVoicePlayback,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: LinearProgressIndicator(
            value: widget.message.voiceDuration != null &&
                    widget.message.voiceDuration!.inMilliseconds > 0
                ? (_position.inMilliseconds /
                        widget.message.voiceDuration!.inMilliseconds)
                    .clamp(0.0, 1.0)
                : 0.0,
            backgroundColor: isMe
                ? const Color(0xFF163917).withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(fg),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          durationText,
          style: TextStyle(
            fontSize: 12,
            color: isMe ? const Color(0xFF163917) : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    switch (widget.message.status) {
      case MessageStatus.pending:
        return Icon(
          Icons.access_time,
          size: 13,
          color: const Color(0xFF163917).withValues(alpha: 0.55),
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 13,
          color: Colors.redAccent,
        );
      case MessageStatus.sent:
        return Icon(
          widget.message.isRead ? Icons.done_all : Icons.done,
          size: 14,
          color: widget.message.isRead
              ? AppTheme.textingSendBtn
              : const Color(0xFF163917).withValues(alpha: 0.55),
        );
    }
  }
}
