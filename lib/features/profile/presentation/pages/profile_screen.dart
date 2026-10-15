import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/notifier/session_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    await ref.read(authRepositoryProvider).signOut();
    ref.read(currentUserProvider.notifier).state = null;
    navigator.pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final picture = user?.profilePicture;
    final name = user?.displayName ?? '';
    final username = user?.username;
    final email = user?.email;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTitle : AppTheme.header,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: CircleAvatar(
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
              Text(
                '@$username',
                textAlign: TextAlign.center,
                style: AppTextStyle.bodySecondary,
              ),
            ],
            if (email != null) ...[
              const SizedBox(height: 2),
              Text(
                email,
                textAlign: TextAlign.center,
                style: AppTextStyle.bodySecondary,
              ),
            ],
            const SizedBox(height: 40),
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
