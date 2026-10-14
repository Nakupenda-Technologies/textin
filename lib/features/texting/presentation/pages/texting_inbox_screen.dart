import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../models/conversation.dart';
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
  final List<(String, Widget?)> _filters = [
    ('All', null),
    ('Unread', null),
    (
      'Aura Active',
      SvgPicture.asset(
        'assets/svgs/aura_active_icon.svg',
        width: 14,
        height: 14,
      ),
    ),
    ('Archived', const Icon(Icons.archive_outlined, size: 14)),
  ];

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
        myUsername: ref.read(currentUserProvider)?.username,
        onSelectUser: (user) async {
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          final result = await locator<TextingRepository>().startOrGetChat(
            otherUserId: user.id,
            myUserId: myUserId,
          );
          result.fold(
            (failure) {
              messenger.showSnackBar(SnackBar(content: Text(failure.message)));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'TEXTin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTitle : AppTheme.header,
                ),
              ),
            ),
            _SearchField(
              controller: _searchController,
              onChanged: (q) =>
                  ref.read(inboxNotifierProvider.notifier).search(q),
            ),
            _buildFilterChips(state),
            if (state.secretConversationsCount > 0)
              _SecretInboxCard(
                count: state.secretConversationsCount,
                onTap: _openSecretInbox,
              ),
            Expanded(child: _buildConversations(state)),
          ],
        ),
      ),
      floatingActionButton: _NewChatButton(onTap: _openNewChatModal),
    );
  }

  Widget _buildConversations(InboxState state) {
    if (state.status == InboxStatus.loading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayed = state.displayedConversations;
    if (displayed.isEmpty) {
      return Center(
        child: Text(
          'No conversations yet 💬',
          style: AppTextStyle.bodySecondary,
        ),
      );
    }

    final pinned = displayed.where((c) => c.isPinned).toList();
    final recent = displayed.where((c) => !c.isPinned).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(inboxNotifierProvider.notifier).loadConversations(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (pinned.isNotEmpty) ...[
            const _SectionLabel('PINNED'),
            for (final c in pinned) _buildTile(c),
          ],
          if (recent.isNotEmpty) ...[
            const _SectionLabel('RECENT'),
            for (final c in recent) _buildTile(c),
          ],
        ],
      ),
    );
  }

  Widget _buildTile(Conversation conversation) {
    final notifier = ref.read(inboxNotifierProvider.notifier);
    return ConversationTile(
      conversation: conversation,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TextingChatScreen(conversation: conversation),
          ),
        ).then((_) => notifier.loadConversations());
      },
      onTogglePin: () => notifier.togglePin(conversation.id),
      onToggleSecret: () => notifier.toggleSecretInbox(conversation.id),
      onMarkRead: () => notifier.markRead(conversation.id),
    );
  }

  Widget _buildFilterChips(InboxState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 30,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = state.selectedFilterIndex == index;
          final (label, icon) = _filters[index];

          return GestureDetector(
            onTap: () =>
                ref.read(inboxNotifierProvider.notifier).setFilter(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? AppTheme.darkRedBg
                          : AppTheme.textingTagRomanticBg2)
                    : (isDark ? AppTheme.darkSurface : AppTheme.bg),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.textingActiveRedBorder
                      : (isDark ? AppTheme.darkBorder : AppTheme.grayBg),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextingFilterInactiveFg
                          : AppTheme.pillRed,
                    ),
                  ),
                  if (icon != null) ...[const SizedBox(width: 8), icon],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.grayBg,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppTheme.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: 'Type to search',
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.grey,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textingSectionLabel,
        ),
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppTheme.textingTagRomanticReceivedBg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppTheme.textred,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, size: 18, color: Colors.white),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [AppTheme.redbg, AppTheme.pinkbg],
            ),
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
                      '$count hidden ${count == 1 ? 'message' : 'messages'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textred,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
