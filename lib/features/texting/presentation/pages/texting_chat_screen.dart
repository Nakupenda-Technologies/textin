import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../user_profile/presentation/pages/user_profile_screen.dart';
import '../../models/api/chat_streak.dart';
import '../../models/conversation.dart';
import '../../notifier/chat_notifier.dart';
import '../../notifier/inbox_notifier.dart';
import '../widgets/chat_mood_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/mood_palette.dart';
import '../widgets/texting_composer.dart';

class TextingChatScreen extends ConsumerWidget {
  const TextingChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserId = ref.watch(myUserIdProvider);
    final chatArgs = ChatArgs(
      chatId: conversation.id,
      otherUserId: conversation.id,
      myUserId: myUserId,
      initialMessages: conversation.messages,
      initialCustomization: conversation.customization,
    );

    return _ChatView(conversation: conversation, args: chatArgs);
  }
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView({required this.conversation, required this.args});

  final Conversation conversation;
  final ChatArgs args;

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatNotifierProvider(widget.args).notifier).loadMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatNotifierProvider(widget.args), (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });

    final state = ref.watch(chatNotifierProvider(widget.args));
    final chatNotifier = ref.read(chatNotifierProvider(widget.args).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customization = state.customization;
    final accent = MoodPalette.of(customization.mood).accent;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkChatAreaBg : AppTheme.chatAreaBg,
      appBar: _ChatHeader(
        conversation: widget.conversation,
        isTyping: state.isOtherUserTyping,
        streak: state.streak,
      ),
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.9,
                  colors: [
                    accent.withValues(alpha: customization.auraGlow * 0.12),
                    accent.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Builder(
                builder: (context) {
                  if (state.status == ChatStatus.loading &&
                      state.messages.isEmpty) {
                    return const _MessagesShimmer();
                  }

                  if (state.messages.isEmpty && !state.isOtherUserTyping) {
                    return Center(
                      child: Text(
                        'No messages yet 💬',
                        style: AppTextStyle.bodySecondary,
                      ),
                    );
                  }

                  final messages = state.messages;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount:
                        messages.length + (state.isOtherUserTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const _TypingIndicator();
                      }

                      final msg = messages[index];
                      final startsNewDay =
                          index == 0 ||
                          !DateUtils.isSameDay(
                            messages[index - 1].timestamp,
                            msg.timestamp,
                          );

                      return Column(
                        children: [
                          if (startsNewDay) _DayChip(date: msg.timestamp),
                          MessageBubble(
                            message: msg,
                            customization: customization,
                            onReply: () => chatNotifier.setReplyingTo(msg),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          TextingComposer(
            initialDraft: state.draftText,
            replyingTo: state.replyingTo,
            onCancelReply: () => chatNotifier.setReplyingTo(null),
            onSendText: (text) => chatNotifier.sendText(text),
            onSendImage: (path) => chatNotifier.sendImage(path),
            onSendVoice: (path, dur) => chatNotifier.sendVoiceNote(path, dur),
            onTyping: (isTyping) => chatNotifier.emitTyping(isTyping),
            onOpenAura: () => ChatMoodSheet.show(
              context,
              initial: customization,
              onChanged: chatNotifier.updateCustomization,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const _ChatHeader({
    required this.conversation,
    required this.isTyping,
    required this.streak,
  });

  final Conversation conversation;
  final bool isTyping;
  final ChatStreak? streak;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  String? get _subtitle {
    if (isTyping) return 'typing...';
    if (conversation.isOnline) return 'Online';
    final lastSeen = conversation.lastSeen;
    if (lastSeen == null) return null;

    final diff = DateTime.now().difference(lastSeen);
    final ago = diff.inMinutes < 1
        ? 'just now'
        : diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : diff.inHours < 24
        ? '${diff.inHours}h ago'
        : '${diff.inDays}d ago';
    return 'Last Seen - $ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final subtitle = _subtitle;
    final otherUserId = conversation.otherUserId;

    return Material(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              _HeaderButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: otherUserId == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => UserProfileScreen(
                              userId: otherUserId,
                              name: conversation.name,
                              avatarUrl: conversation.avatarUrl,
                            ),
                          ),
                        ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                        backgroundImage: conversation.avatarUrl != null
                            ? CachedNetworkImageProvider(
                                conversation.avatarUrl!,
                              )
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    conversation.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? cs.onSurface
                                          : AppTheme.subtitle,
                                    ),
                                  ),
                                ),
                                if (streak != null && streak!.count > 0) ...[
                                  const SizedBox(width: 6),
                                  _StreakBadge(streak: streak!),
                                ],
                              ],
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: -0.04,
                                  fontStyle: isTyping
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  color: isTyping
                                      ? AppTheme.textingSentBubble
                                      : AppTheme.iconColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _HeaderButton(
                icon: Icons.call,
                outlined: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio calling is coming soon!'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _HeaderButton(icon: Icons.more_vert, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});

  final ChatStreak streak;

  @override
  Widget build(BuildContext context) {
    final kept = streak.isKeptOn(DateTime.now());
    final level = streak.level.isEmpty
        ? ''
        : '${streak.level[0].toUpperCase()}${streak.level.substring(1)} streak · ';

    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: kept
          ? '${level}kept for today'
          : '${level}send a message today to keep it',
      child: Text(
        kept ? '🔥 ${streak.count}' : '🔥 ${streak.count} ⏳',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kept ? AppTheme.textred : AppTheme.iconColor,
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: outlined
          ? cs.surface
          : (isDark ? AppTheme.darkSurface2 : AppTheme.insideGrey),
      shape: CircleBorder(
        side: outlined
            ? BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.grayBg)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: cs.onSurface),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date});

  final DateTime date;

  String get _label {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return DateFormat('d MMM y').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkTextingDateChipBg
              : AppTheme.textingDateChipBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? cs.onSurface : AppTheme.textingDateChipFg,
          ),
        ),
      ),
    );
  }
}

class _MessagesShimmer extends StatelessWidget {
  const _MessagesShimmer();

  static const _bubbles = [
    (false, 180.0),
    (true, 140.0),
    (false, 220.0),
    (false, 120.0),
    (true, 200.0),
    (false, 160.0),
    (true, 120.0),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          for (final (isMe, width) in _bubbles)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ShimmerBlock(width: width, height: 38, radius: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkTextingReceivedBubble
              : AppTheme.textingReceivedBubble,
          borderRadius: BorderRadius.circular(24),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.red.withValues(
                      alpha: ((_controller.value * 3 - i) % 3) < 1 ? 1 : 0.4,
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
