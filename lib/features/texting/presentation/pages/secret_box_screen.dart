import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../cubit/inbox/inbox_cubit.dart';
import '../../cubit/secret_box/secret_box_cubit.dart';
import '../../cubit/secret_box/secret_box_state.dart';
import '../../repository/texting_repository.dart';
import '../widgets/conversation_tile.dart';
import 'texting_chat_screen.dart';

class SecretBoxScreen extends StatelessWidget {
  const SecretBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUserId = context.read<InboxCubit>().myUserId;

    return BlocProvider(
      create: (_) => SecretBoxCubit(
        repository: locator<TextingRepository>(),
        myUserId: myUserId,
      )..loadSecretChats(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.lock, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Secret Inbox', style: AppTextStyle.heading2),
            ],
          ),
        ),
        body: BlocBuilder<SecretBoxCubit, SecretBoxState>(
          builder: (context, state) {
            if (state.secretConversations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_person_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Secret Inbox is Empty',
                        style: AppTextStyle.heading3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Move conversations here from the inbox to hide them behind your PIN.',
                        style: AppTextStyle.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: state.secretConversations.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 74),
              itemBuilder: (context, index) {
                final chat = state.secretConversations[index];
                return ConversationTile(
                  conversation: chat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TextingChatScreen(conversation: chat),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
