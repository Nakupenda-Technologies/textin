import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';


class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
    this.onTogglePin,
    this.onToggleSecret,
    this.onMarkRead,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleSecret;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress ?? () => _showActionMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(conversation: conversation),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                conversation.name,
                                style: AppTextStyle.heading3.copyWith(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversation.hasFireBadge) ...[
                              const SizedBox(width: 4),
                              const Text('🔥', style: TextStyle(fontSize: 14)),
                            ],
                            if (conversation.isPinned) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.push_pin,
                                size: 14,
                                color: AppTheme.red,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conversation.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: conversation.unreadCount > 0
                              ? AppTheme.red
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (conversation.tag != ConversationTag.none)
                        _TagChip(tag: conversation.tag),
                      Expanded(
                        child: _LastMessageSnippet(conversation: conversation),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppTheme.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conversation.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: AppColors.primary,
              ),
              title: Text(conversation.isPinned ? 'Unpin chat' : 'Pin chat'),
              onTap: () {
                Navigator.pop(ctx);
                onTogglePin?.call();
              },
            ),
            ListTile(
              leading: Icon(
                conversation.inSecretInbox ? Icons.lock_open : Icons.lock_outline,
                color: AppColors.primary,
              ),
              title: Text(
                conversation.inSecretInbox
                    ? 'Move out of Secret Inbox'
                    : 'Move to Secret Inbox',
              ),
              onTap: () {
                Navigator.pop(ctx);
                onToggleSecret?.call();
              },
            ),
            if (conversation.unreadCount > 0)
              ListTile(
                leading: const Icon(Icons.mark_chat_read, color: AppColors.success),
                title: const Text('Mark as read'),
                onTap: () {
                  Navigator.pop(ctx);
                  onMarkRead?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.onSurface.withValues(alpha: 0.10),
          backgroundImage: conversation.avatarUrl != null
              ? CachedNetworkImageProvider(conversation.avatarUrl!)
              : null,
          child: conversation.avatarUrl == null
              ? Text(
                  conversation.name.isNotEmpty
                      ? conversation.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        if (conversation.isOnline)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.textingOnlineDot,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final ConversationTag tag;

  String get label {
    switch (tag) {
      case ConversationTag.romantic:
        return 'Romantic';
      case ConversationTag.professional:
        return 'Professional';
      case ConversationTag.chill:
        return 'Chill';
      case ConversationTag.excited:
        return 'Excited';
      case ConversationTag.none:
        return '';
    }
  }

  Color get bg {
    switch (tag) {
      case ConversationTag.romantic:
        return AppTheme.textingTagRomanticBg;
      case ConversationTag.professional:
        return AppTheme.textingTagProfessionalBg;
      case ConversationTag.chill:
        return AppTheme.textingTagChillBg;
      case ConversationTag.excited:
        return AppTheme.textingTagExcitedBg;
      case ConversationTag.none:
        return Colors.transparent;
    }
  }

  Color get fg {
    switch (tag) {
      case ConversationTag.romantic:
        return Colors.white;
      case ConversationTag.professional:
        return AppTheme.textingTagProfessionalFg;
      case ConversationTag.chill:
        return AppTheme.textingTagChillFg;
      case ConversationTag.excited:
        return AppTheme.textingTagExcitedFg;
      case ConversationTag.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tag == ConversationTag.none) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}


class _LastMessageSnippet extends StatelessWidget {
  const _LastMessageSnippet({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final msg = conversation.lastMessage;
    if (msg == null) {
      return Text(
        'No messages yet',
        style: AppTextStyle.bodySecondary,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (msg.type == MessageType.voice) {
      return Row(
        children: [
          const Icon(Icons.mic, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            'Voice message (${msg.formattedDuration})',
            style: AppTextStyle.bodySecondary,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    if (msg.type == MessageType.image) {
      return Row(
        children: [
          const Icon(Icons.image, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('Photo', style: AppTextStyle.bodySecondary),
        ],
      );
    }

    return Text(
      msg.content,
      style: AppTextStyle.bodySecondary.copyWith(
        fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
        color: conversation.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
