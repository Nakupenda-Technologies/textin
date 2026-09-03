import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
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
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conversation.timeAgo,
                        style: AppTextStyle.bodySecondary.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: _LastMessageSnippet(conversation: conversation),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
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
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: conversation.avatarUrl != null
              ? CachedNetworkImageProvider(conversation.avatarUrl!)
              : null,
          child: conversation.avatarUrl == null
              ? Text(
                  conversation.name.isNotEmpty
                      ? conversation.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                )
              : null,
        ),
        if (conversation.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
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
