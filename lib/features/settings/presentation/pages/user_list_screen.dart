import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../data_source/settings_remote_data_source.dart';
import '../../models/listed_user.dart';
import '../../repository/settings_repository.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key, required this.kind});

  final UserListKind kind;

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<ListedUser>? _users;
  String? _error;

  SettingsRepository get _repository => locator<SettingsRepository>();

  (String title, String action, String empty) get _copy =>
      switch (widget.kind) {
        UserListKind.blocked => (
          'Blocked users',
          'Unblock',
          "You haven't blocked anyone",
        ),
        UserListKind.muted => (
          'Muted users',
          'Unmute',
          "You haven't muted anyone",
        ),
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await _repository.fetchUsers(widget.kind);
    if (!mounted) return;
    setState(
      () => result.fold((f) => _error = f.message, (users) => _users = users),
    );
  }

  Future<void> _remove(ListedUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _repository.removeUser(widget.kind, user.id);
    if (!mounted) return;
    result.fold(
      (f) => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (_) => setState(
        () => _users = [
          for (final u in _users ?? const <ListedUser>[])
            if (u.id != user.id) u,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (title, _, _) = _copy;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final users = _users;
    final (_, action, empty) = _copy;

    if (_error != null && users == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyle.bodySecondary),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (users == null) return const ShimmerList(itemCount: 5);
    if (users.isEmpty) {
      return Center(child: Text(empty, style: AppTextStyle.bodySecondary));
    }

    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, index) {
        final user = users[index];
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
                  )
                : null,
          ),
          title: Text(user.displayName),
          subtitle: user.username != null ? Text('@${user.username}') : null,
          trailing: OutlinedButton(
            onPressed: () => _remove(user),
            child: Text(action),
          ),
        );
      },
    );
  }
}
