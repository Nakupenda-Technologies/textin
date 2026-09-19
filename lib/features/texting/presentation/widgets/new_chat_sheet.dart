import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/following_user.dart';
import '../../repository/texting_repository.dart';

class NewChatSheet extends StatefulWidget {
  const NewChatSheet({
    super.key,
    required this.repository,
    required this.myUserId,
    required this.onSelectUser,
  });

  final TextingRepository repository;
  final String myUserId;
  final ValueChanged<FollowingUser> onSelectUser;

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<FollowingUser> _users = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final result = await widget.repository.fetchFollowingUsers('me');
    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _users = [];
        });
      },
      (list) {
        setState(() {
          _isLoading = false;
          _users = list;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return u.displayName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q);
    }).toList();

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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No contacts found 👥',
                          style: AppTextStyle.bodySecondary,
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 68),
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          final cs = Theme.of(context).colorScheme;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                              backgroundImage: user.profilePicture != null
                                  ? CachedNetworkImageProvider(
                                      user.profilePicture!,
                                    )
                                  : null,
                              child: user.profilePicture == null
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
                              style: AppTextStyle.bodySecondary.copyWith(
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSelectUser(user);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
