import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/env/env.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
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
          if (state.secretConversationsCount > 0)
            _SecretInboxCard(
              count: state.secretConversationsCount,
              onTap: _openSecretInbox,
            ),
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
                          'No conversations yet 💬',
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
        heroTag: 'texting_fab',
        backgroundColor: AppTheme.red,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: _openNewChatModal,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildFilterChips(InboxState state) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = state.selectedFilterIndex == index;
          final label = _filters[index];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isSelected
              ? Colors.white
              : (isDark
                  ? AppTheme.darkTextingFilterInactiveFg
                  : AppTheme.textingFilterInactiveFg);

          return GestureDetector(
            onTap: () =>
                ref.read(inboxNotifierProvider.notifier).setFilter(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.textingTagRomanticBg
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: isSelected
                    ? Border.all(color: AppTheme.textingActiveRedBorder, width: 1)
                    : Border.all(
                        color: Theme.of(context).dividerColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (index == 1 && state.totalUnreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppTheme.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        state.totalUnreadCount.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.red : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SecretInboxCard extends StatelessWidget {
  const _SecretInboxCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.textingSecretInboxBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.textingSecretInboxBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.textingSecretInboxBorder),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secret inbox',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count hidden messages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

