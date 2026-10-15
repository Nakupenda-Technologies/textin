import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../../settings/presentation/pages/edit_profile_screen.dart';
import '../../../settings/presentation/pages/settings_screen.dart';
import '../../../settings/presentation/widgets/settings_tiles.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await signOutToLogin(ref);
  }

  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTitle : AppTheme.header,
              ),
            ),
            const _ProfileHeader(),
            const SizedBox(height: 24),
            SettingsRow(
              title: 'Edit profile',
              subtitle: 'Name, bio and photo',
              trailing: const SettingsValueLink(),
              onTap: () => _open(const EditProfileScreen()),
            ),
            SettingsRow(
              title: 'Settings',
              subtitle: 'Account, privacy, notifications and more',
              trailing: const SettingsValueLink(),
              onTap: () => _open(const SettingsScreen()),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Sign out',
              variant: AppButtonVariant.outline,
              isLoading: _isSigningOut,
              onPressed: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final picture = user?.profilePicture;
    final name = user?.displayName ?? '';
    final username = user?.username;
    final email = user?.email;

    return Column(
      children: [
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 44,
          backgroundColor: cs.onSurface.withValues(alpha: 0.10),
          backgroundImage: picture != null
              ? CachedNetworkImageProvider(picture)
              : null,
          child: picture == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        if (username != null) ...[
          const SizedBox(height: 4),
          Text('@$username', style: AppTextStyle.bodySecondary),
        ],
        if (email != null) ...[
          const SizedBox(height: 2),
          Text(email, style: AppTextStyle.bodySecondary),
        ],
      ],
    );
  }
}
