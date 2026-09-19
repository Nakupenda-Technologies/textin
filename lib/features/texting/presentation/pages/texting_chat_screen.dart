import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/conversation.dart';
import '../../notifier/chat_notifier.dart';
import '../../notifier/inbox_notifier.dart';
import '../widgets/message_bubble.dart';
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
    );

    return _ChatView(
      conversation: conversation,
      args: chatArgs,
    );
  }
}

class _ChatView extends ConsumerStatefulWidget {
  const _ChatView({
    required this.conversation,
    required this.args,
  });

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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkChatAreaBg : AppTheme.chatAreaBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.onSurface.withValues(alpha: 0.10),
              backgroundImage: widget.conversation.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.conversation.avatarUrl!)
                  : null,
              child: widget.conversation.avatarUrl == null
                  ? Text(
                      widget.conversation.name.isNotEmpty
                          ? widget.conversation.name[0].toUpperCase()
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
                children: [
                  Text(
                    widget.conversation.name,
                    style: AppTextStyle.heading3.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (state.isOtherUserTyping)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.red,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      widget.conversation.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.conversation.isOnline
                            ? AppTheme.textingOnlineDot
                            : cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video calling is coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio calling is coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.status == ChatStatus.loading && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet 💬',
                      style: AppTextStyle.bodySecondary,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    return MessageBubble(
                      message: msg,
                      onReply: () {
                        chatNotifier.setReplyingTo(msg);
                      },
                    );
                  },
                );
              },
            ),
          ),
          TextingComposer(
            initialDraft: state.draftText,
            replyingTo: state.replyingTo,
            onCancelReply: () => chatNotifier.setReplyingTo(null),
            onSendText: (text) => chatNotifier.sendText(text),
            onSendImage: (path) => chatNotifier.sendText('[Image attached]'),
            onSendVoice: (path, dur) => chatNotifier.sendVoiceNote(path, dur),
            onTyping: (isTyping) => chatNotifier.emitTyping(isTyping),
          ),
        ],
      ),
    );
  }
}
