import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../cubit/chat/chat_cubit.dart';
import '../../cubit/chat/chat_state.dart';
import '../../cubit/inbox/inbox_cubit.dart';
import '../../models/conversation.dart';
import '../../repository/texting_repository.dart';
import '../../services/texting_socket_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/texting_composer.dart';

class TextingChatScreen extends StatelessWidget {
  const TextingChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final myUserId = context.read<InboxCubit>().myUserId;

    return BlocProvider(
      create: (_) => ChatCubit(
        chatId: conversation.id,
        otherUserId: conversation.id,
        myUserId: myUserId,
        repository: locator<TextingRepository>(),
        socketService: locator<TextingSocketService>(),
        initialMessages: conversation.messages,
      )..loadMessages(),
      child: _ChatView(conversation: conversation),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.conversation});

  final Conversation conversation;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final ScrollController _scrollController = ScrollController();

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: widget.conversation.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.conversation.avatarUrl!)
                  : null,
              child: widget.conversation.avatarUrl == null
                  ? Text(
                      widget.conversation.name.isNotEmpty
                          ? widget.conversation.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
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
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      if (state.isOtherUserTyping) {
                        return const Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return Text(
                        widget.conversation.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.conversation.isOnline
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      );
                    },
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
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              },
              builder: (context, state) {
                if (state.status == ChatStatus.loading && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
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
                        context.read<ChatCubit>().setReplyingTo(msg);
                      },
                    );
                  },
                );
              },
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              return TextingComposer(
                initialDraft: state.draftText,
                replyingTo: state.replyingTo,
                onCancelReply: () =>
                    context.read<ChatCubit>().setReplyingTo(null),
                onSendText: (text) =>
                    context.read<ChatCubit>().sendText(text),
                onSendImage: (path) =>
                    context.read<ChatCubit>().sendText('[Image attached]'),
                onSendVoice: (path, dur) =>
                    context.read<ChatCubit>().sendVoiceNote(path, dur),
                onTyping: (isTyping) =>
                    context.read<ChatCubit>().emitTyping(isTyping),
              );
            },
          ),
        ],
      ),
    );
  }
}
