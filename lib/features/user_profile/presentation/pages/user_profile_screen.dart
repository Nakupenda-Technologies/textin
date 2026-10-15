import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../models/user_profile.dart';
import '../../notifier/user_profile_notifier.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(userProfileNotifierProvider(userId));
    final notifier = ref.read(userProfileNotifierProvider(userId).notifier);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _BackButton(),
            _Header(
              name: profile?.displayName ?? name,
              avatarUrl: profile?.profilePicture ?? avatarUrl,
              username: profile?.username,
              isVerified: profile?.isVerified ?? false,
            ),
            const SizedBox(height: 24),
            if (profile != null) ...[
              _Details(profile: profile),
              const SizedBox(height: 24),
              _Actions(
                profile: profile,
                onFollow: notifier.toggleFollow,
                onMute: notifier.toggleMute,
                onBlock: () async {
                  if (profile.isBlocked ||
                      await _confirmBlock(context, profile)) {
                    notifier.toggleBlock();
                  }
                },
              ),
            ] else if (state.status == UserProfileStatus.error)
              _LoadError(
                message: state.errorMessage ?? "We couldn't load this profile",
                onRetry: notifier.load,
              )
            else
              const _DetailsShimmer(),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmBlock(BuildContext context, UserProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block @${profile.username}?'),
        content: const Text(
          "They won't be able to message you or see your activity.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.textred),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(
              PhosphorIconsBold.arrowLeft,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
              semanticLabel: 'Back',
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.avatarUrl,
    required this.username,
    required this.isVerified,
  });

  final String name;
  final String? avatarUrl;
  final String? username;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final picture = avatarUrl;

    return Column(
      children: [
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 48,
          backgroundColor: cs.onSurface.withValues(alpha: 0.10),
          backgroundImage: picture != null
              ? CachedNetworkImageProvider(picture)
              : null,
          child: picture == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 6),
              const Icon(
                PhosphorIconsFill.sealCheck,
                size: 18,
                color: AppTheme.textred,
                semanticLabel: 'Verified',
              ),
            ],
          ],
        ),
        if (username != null) ...[
          const SizedBox(height: 4),
          Text('@$username', style: AppTextStyle.bodySecondary),
        ],
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final countStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
    final bio = profile.bio;

    return Column(
      children: [
        if (bio != null) ...[
          Text(
            bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${profile.followersCount}', style: countStyle),
            Text(' Followers', style: AppTextStyle.bodySecondary),
            const SizedBox(width: 20),
            Text('${profile.followingCount}', style: countStyle),
            Text(' Following', style: AppTextStyle.bodySecondary),
          ],
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.profile,
    required this.onFollow,
    required this.onMute,
    required this.onBlock,
  });

  final UserProfile profile;
  final VoidCallback onFollow;
  final VoidCallback onMute;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final handle = '@${profile.username}';

    return Column(
      children: [
        _ActionRow(
          icon: profile.isFollowing
              ? PhosphorIconsRegular.userMinus
              : PhosphorIconsRegular.userPlus,
          label: profile.isFollowing ? 'Unfollow $handle' : 'Follow $handle',
          onTap: onFollow,
        ),
        _ActionRow(
          icon: profile.isMuted
              ? PhosphorIconsRegular.speakerHigh
              : PhosphorIconsRegular.speakerSlash,
          label: profile.isMuted ? 'Unmute $handle' : 'Mute $handle',
          onTap: onMute,
        ),
        _ActionRow(
          icon: PhosphorIconsRegular.prohibit,
          label: profile.isBlocked ? 'Unblock $handle' : 'Block $handle',
          destructive: true,
          onTap: onBlock,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = destructive
        ? AppTheme.textred
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppTheme.darkSurface : AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.border,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsShimmer extends StatelessWidget {
  const _DetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          const ShimmerBlock(width: 120, height: 14),
          const SizedBox(height: 16),
          const ShimmerBlock(width: 180, height: 14),
          const SizedBox(height: 32),
          for (var i = 0; i < 3; i++) ...[
            const ShimmerBlock(height: 50, radius: 12),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodySecondary,
        ),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
