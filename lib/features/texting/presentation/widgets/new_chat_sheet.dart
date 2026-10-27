import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/error_message.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../models/following_user.dart';
import '../../repository/texting_repository.dart';

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({
    super.key,
    required this.repository,
    required this.myUserId,
    required this.myUsername,
    required this.onSelectUser,
  });

  final TextingRepository repository;
  final String myUserId;
  final String? myUsername;
  final Future<void> Function(FollowingUser) onSelectUser;

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<FollowingUser> _users = [];
  List<FollowingUser> _suggestions = [];
  final Set<String> _pendingFollows = {};
  String? _openingUserId;
  bool _isLoading = false;
  String? _loadError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final username = widget.myUsername;
    if (username == null || username.isEmpty) {
      setState(() {
        _users = [];
        _loadError =
            "We couldn't load your contacts. Sign out and sign in again.";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final (following, suggested) = await (
      widget.repository.fetchFollowingUsers(username),
      widget.repository.fetchSuggestedUsers(),
    ).wait;
    if (!mounted) return;
    following.fold(
      (failure) => setState(() {
        _isLoading = false;
        _users = [];
        _loadError = userMessage(failure);
      }),
      (list) => setState(() {
        _isLoading = false;
        _users = list;
        final followedIds = {for (final u in list) u.id, widget.myUserId};
        _suggestions = suggested
            .getOrElse(() => [])
            .where((u) => !followedIds.contains(u.id))
            .toList();
      }),
    );
  }

  Future<void> _follow(FollowingUser user) async {
    setState(() => _pendingFollows.add(user.id));
    final result = await widget.repository.followUser(user.username);
    if (!mounted) return;
    setState(() => _pendingFollows.remove(user.id));
    result.fold(
      (failure) =>
          AppToast.failure("Couldn't follow @${user.username}", failure),
      (_) {
        setState(() {
          _suggestions = _suggestions.where((u) => u.id != user.id).toList();
          _users = [user, ..._users];
        });
        AppToast.show('You can now chat with ${user.displayName}');
      },
    );
  }

  Future<void> _open(FollowingUser user) async {
    if (_openingUserId != null) return;
    setState(() => _openingUserId = user.id);
    await widget.onSelectUser(user);
    if (mounted) setState(() => _openingUserId = null);
  }

  bool _matches(FollowingUser user) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return user.displayName.toLowerCase().contains(q) ||
        user.username.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New Conversation', style: AppTextStyle.heading2),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search people by name or username...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextingInputBg
                    : AppTheme.textingInputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const ShimmerList();

    if (_loadError case final error?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyle.bodySecondary,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadUsers, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final contacts = _users.where(_matches).toList();
    final suggestions = _suggestions.where(_matches).toList();

    if (contacts.isEmpty && suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _users.isEmpty && _query.isEmpty
                ? 'Follow people to start chatting with them 💬'
                : 'No people found',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySecondary,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_users.isEmpty && _query.isEmpty)
          const _Hint(
            'You can only chat with people you follow. '
            'Follow someone below to start a conversation.',
          ),
        for (final user in contacts)
          _PersonTile(
            user: user,
            trailing: _openingUserId == user.id
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
            onTap: () => _open(user),
          ),
        if (suggestions.isNotEmpty) ...[
          const _SectionLabel('Suggested for you'),
          for (final user in suggestions)
            _PersonTile(
              user: user,
              trailing: _FollowButton(
                isPending: _pendingFollows.contains(user.id),
                onPressed: () => _follow(user),
              ),
            ),
        ],
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(text, style: AppTextStyle.bodySecondary),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: AppTextStyle.heading3.copyWith(fontSize: 14)),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.user, required this.trailing, this.onTap});

  final FollowingUser user;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final picture = user.profilePicture;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: cs.onSurface.withValues(alpha: 0.10),
        backgroundImage: picture != null
            ? CachedNetworkImageProvider(picture)
            : null,
        child: picture == null
            ? Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.displayName,
        style: AppTextStyle.heading3.copyWith(fontSize: 15),
      ),
      subtitle: Text(
        '@${user.username}${user.bio != null ? ' • ${user.bio}' : ''}',
        style: AppTextStyle.bodySecondary.copyWith(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isPending, required this.onPressed});

  final bool isPending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isPending ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.textred,
        foregroundColor: Colors.white,
        minimumSize: const Size(84, 34),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: isPending
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Follow'),
    );
  }
}
