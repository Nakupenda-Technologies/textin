import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/env/env.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../notifier/inbox_notifier.dart';
import '../../repository/texting_repository.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/new_chat_sheet.dart';
import 'secret_box_pin_screen.dart';
import 'texting_chat_screen.dart';

class TextingInboxScreen extends ConsumerStatefulWidget {
  const TextingInboxScreen({super.key});

  @override
  ConsumerState<TextingInboxScreen> createState() => _TextingInboxScreenState();
}

class _TextingInboxScreenState extends ConsumerState<TextingInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _filters = ['All', 'Unread', 'Active', 'Archived'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(inboxNotifierProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewChatModal() {
    final myUserId = ref.read(myUserIdProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewChatSheet(
        repository: locator<TextingRepository>(),
        myUserId: myUserId,
        onSelectUser: (user) async {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          final result = await locator<TextingRepository>().startOrGetChat(
            otherUserId: user.id,
            myUserId: myUserId,
          );
          result.fold(
            (failure) {
              messenger.showSnackBar(
                SnackBar(content: Text(failure.message)),
              );
            },
            (conversation) {
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => TextingChatScreen(conversation: conversation),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openSecretInbox() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SecretBoxPinScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  border: InputBorder.none,
                ),
                onChanged: (q) =>
                    ref.read(inboxNotifierProvider.notifier).search(q),
              )
            : Row(
                children: [
                  Text(Env.appName, style: AppTextStyle.heading1.copyWith(fontSize: 22)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      Env.flavor.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(inboxNotifierProvider.notifier).search('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Secret Inbox',
            onPressed: _openSecretInbox,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(state),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state.status == InboxStatus.loading &&
                    state.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final displayed = state.displayedConversations;
                if (displayed.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 56,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No conversations found',
                          style: AppTextStyle.heading3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to start a new chat with your contacts',
                          style: AppTextStyle.bodySecondary,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(inboxNotifierProvider.notifier).loadConversations(),
                  child: ListView.separated(
                    itemCount: displayed.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 74,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final conversation = displayed[index];
                      return ConversationTile(
                        conversation: conversation,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TextingChatScreen(
                                conversation: conversation,
                              ),
                            ),
                          ).then((_) {
                            ref
                                .read(inboxNotifierProvider.notifier)
                                .loadConversations();
                          });
                        },
                        onTogglePin: () => ref
                            .read(inboxNotifierProvider.notifier)
                            .togglePin(conversation.id),
                        onToggleSecret: () => ref
                            .read(inboxNotifierProvider.notifier)
                            .toggleSecretInbox(conversation.id),
                        onMarkRead: () => ref
                            .read(inboxNotifierProvider.notifier)
                            .markRead(conversation.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openNewChatModal,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildFilterChips(InboxState state) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = state.selectedFilterIndex == index;
          final label = _filters[index];

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (index == 1 && state.totalUnreadCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.totalUnreadCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            showCheckmark: false,
            onSelected: (_) =>
                ref.read(inboxNotifierProvider.notifier).setFilter(index),
          );
        },
      ),
    );
  }
}
