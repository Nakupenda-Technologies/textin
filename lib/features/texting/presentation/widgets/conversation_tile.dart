import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress ?? () => _showActionMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
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
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? cs.onSurface
                                      : AppTheme.subtitle,
                                ),
                              ),
                            ),
                            if (conversation.hasFireBadge) ...[
                              const SizedBox(width: 4),
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conversation.timeAgo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: hasUnread
                              ? AppTheme.textred
                              : (isDark ? cs.onSurface : AppTheme.subtitle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (conversation.tag != ConversationTag.none)
                        _TagChip(tag: conversation.tag),
                      Expanded(
                        child: _LastMessageSnippet(conversation: conversation),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.textred,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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
                conversation.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin,
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
                conversation.inSecretInbox
                    ? Icons.lock_open
                    : Icons.lock_outline,
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
                leading: const Icon(
                  Icons.mark_chat_read,
                  color: AppColors.success,
                ),
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
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 1.5,
              color: conversation.isOnline
                  ? AppTheme.textingActiveRedBorder
                  : Colors.transparent,
            ),
          ),
          child: CircleAvatar(
            radius: 20,
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
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
        ),
        if (conversation.isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.textingOnlineDot,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 1.5),
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

  Color get _color => switch (tag) {
    ConversationTag.romantic => AppTheme.textred,
    ConversationTag.professional => AppTheme.textingTagProfessionalOutline,
    ConversationTag.chill => AppTheme.textingTagChillOutline,
    ConversationTag.excited => AppTheme.textingTagExcitedOutline,
    ConversationTag.none => Colors.transparent,
  };

  @override
  Widget build(BuildContext context) {
    final label = tag.name[0].toUpperCase() + tag.name.substring(1);
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _color, width: 0.75),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: _color,
        ),
      ),
    );
  }
}

class _LastMessageSnippet extends StatelessWidget {
  const _LastMessageSnippet({required this.conversation});

  final Conversation conversation;

  String get _text {
    final msg = conversation.lastMessage;
    if (msg == null) return 'No messages yet';
    return switch (msg.type) {
      MessageType.voice => 'Voice message (${msg.formattedDuration})',
      MessageType.image => 'Sent an image',
      _ => msg.content,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, color: AppTheme.iconColor),
    );
  }
}
