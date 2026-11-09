import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../../settings/presentation/pages/account_settings_screen.dart';
import '../../../settings/presentation/pages/edit_profile_screen.dart';
import '../../../settings/presentation/pages/notification_settings_screen.dart';
import '../../../settings/presentation/pages/preference_settings_screen.dart';
import '../../../settings/presentation/pages/privacy_settings_screen.dart';
import '../../../settings/presentation/pages/whisper_settings_screen.dart';

typedef _Tile = (IconData icon, String title, Widget screen);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const List<List<_Tile>> _groups = [
    [
      (PhosphorIconsRegular.userGear, 'Account', AccountSettingsScreen()),
      (PhosphorIconsRegular.shieldCheck, 'Privacy', PrivacySettingsScreen()),
    ],
    [
      (
        PhosphorIconsRegular.bell,
        'Notifications',
        NotificationSettingsScreen(),
      ),
    ],
    [
      (
        PhosphorIconsRegular.slidersHorizontal,
        'Preferences',
        PreferenceSettingsScreen(),
      ),
    ],
    [(PhosphorIconsRegular.microphone, 'Whispers', WhisperSettingsScreen())],
  ];

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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTitle : AppTheme.title,
              ),
            ),
            const SizedBox(height: 20),
            _ProfileCard(
              children: [
                const _ProfileHeader(),
                _ProfileTile(
                  icon: PhosphorIconsRegular.userCircle,
                  title: 'Edit profile',
                  onTap: () => _open(const EditProfileScreen()),
                ),
              ],
            ),
            for (final group in _groups) ...[
              const SizedBox(height: 12),
              _ProfileCard(
                children: [
                  for (final (icon, title, screen) in group)
                    _ProfileTile(
                      icon: icon,
                      title: title,
                      onTap: () => _open(screen),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _ProfileCard(
              children: [
                _ProfileTile(
                  icon: PhosphorIconsRegular.signOut,
                  title: 'Sign out',
                  color: AppTheme.textred,
                  trailing: _isSigningOut
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textred,
                          ),
                        )
                      : const SizedBox.shrink(),
                  onTap: _isSigningOut ? null : _signOut,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppTheme.darkDivider : AppTheme.cardDivider,
    );

    return Material(
      color: isDark ? AppTheme.darkSurface : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) divider,
              child,
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 22, color: foreground),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, color: foreground),
              ),
            ),
            trailing ??
                Icon(
                  PhosphorIconsBold.caretRight,
                  size: 16,
                  color: foreground.withValues(alpha: 0.7),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: cs.onSurface.withValues(alpha: 0.10),
            backgroundImage: picture != null
                ? CachedNetworkImageProvider(picture)
                : null,
            child: picture == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (username != null) ...[
                  const SizedBox(height: 2),
                  Text('@$username', style: AppTextStyle.bodySecondary),
                ],
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.bodySecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
