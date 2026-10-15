import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../../settings/models/user_settings.dart';
import '../../../settings/notifier/settings_notifier.dart';
import '../../../settings/presentation/pages/edit_profile_screen.dart';
import '../../../settings/presentation/widgets/settings_tiles.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsNotifierProvider.notifier).load());
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    final navigator = Navigator.of(context, rootNavigator: true);
    await ref.read(authRepositoryProvider).signOut();
    ref.read(currentUserProvider.notifier).state = null;
    navigator.pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
  }

  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  void _update(UserSettings settings) =>
      ref.read(settingsNotifierProvider.notifier).update(settings);

  Future<void> _pick<T>({
    required String title,
    required Map<T, String> options,
    required T selected,
    required UserSettings Function(T choice) apply,
  }) async {
    final choice = await showSettingsChoice<T>(
      context,
      title: title,
      options: options,
      selected: selected,
    );
    if (choice != null && choice != selected) _update(apply(choice));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsNotifierProvider, (previous, next) {
      final message = next.errorMessage;
      if (next.status == SettingsStatus.loaded &&
          message != null &&
          message != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final settingsState = ref.watch(settingsNotifierProvider);
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
            ..._buildSettings(settingsState),
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

  List<Widget> _buildSettings(SettingsState state) {
    if (state.status == SettingsStatus.loading) {
      return const [
        SizedBox(height: 24),
        AppShimmer(child: ShimmerBlock(height: 220, radius: 16)),
      ];
    }
    if (state.status == SettingsStatus.error) {
      return [
        const SizedBox(height: 24),
        Text(
          state.errorMessage ?? 'Settings could not be loaded.',
          textAlign: TextAlign.center,
          style: AppTextStyle.bodySecondary,
        ),
        TextButton(
          onPressed: () => ref.read(settingsNotifierProvider.notifier).load(),
          child: const Text('Try again'),
        ),
      ];
    }

    final settings = state.settings;
    return [
      SettingsSection(
        title: 'Account',
        children: [
          SettingsTile(
            icon: PhosphorIconsRegular.userCircleGear,
            title: 'Edit profile',
            onTap: () => _open(const EditProfileScreen()),
          ),
        ],
      ),
      SettingsSection(
        title: 'Privacy',
        children: [
          SettingsTile(
            icon: PhosphorIconsRegular.chatCircleText,
            title: 'Who can message me',
            value: settings.whoCanMessageMe.label,
            onTap: () => _pick(
              title: 'Who can message me',
              options: {for (final p in MessagePermission.values) p: p.label},
              selected: settings.whoCanMessageMe,
              apply: (p) => settings.copyWith(whoCanMessageMe: p),
            ),
          ),
        ],
      ),
      SettingsSection(
        title: 'Notifications',
        children: [
          SettingsSwitchTile(
            icon: PhosphorIconsRegular.bellSimple,
            title: 'Push notifications',
            value: settings.pushNotifications,
            onChanged: (v) => _update(settings.copyWith(pushNotifications: v)),
          ),
          SettingsSwitchTile(
            icon: PhosphorIconsRegular.envelopeSimple,
            title: 'Email notifications',
            value: settings.emailNotifications,
            onChanged: (v) => _update(settings.copyWith(emailNotifications: v)),
          ),
          SettingsSwitchTile(
            icon: PhosphorIconsRegular.waveform,
            title: 'Whisper notifications',
            value: settings.whisperNotifications,
            onChanged: (v) =>
                _update(settings.copyWith(whisperNotifications: v)),
          ),
          SettingsSwitchTile(
            icon: PhosphorIconsRegular.userPlus,
            title: 'Allow whisper invites',
            value: settings.allowWhisperInvites,
            onChanged: (v) =>
                _update(settings.copyWith(allowWhisperInvites: v)),
          ),
          SettingsSwitchTile(
            icon: PhosphorIconsRegular.handWaving,
            title: 'Allow speaker requests',
            value: settings.allowSpeakerRequests,
            onChanged: (v) =>
                _update(settings.copyWith(allowSpeakerRequests: v)),
          ),
        ],
      ),
      SettingsSection(
        title: 'Appearance',
        children: [
          SettingsTile(
            icon: PhosphorIconsRegular.palette,
            title: 'Theme',
            value: settings.theme.label,
            onTap: () => _pick(
              title: 'Theme',
              options: {for (final t in AppThemePreference.values) t: t.label},
              selected: settings.theme,
              apply: (t) => settings.copyWith(theme: t),
            ),
          ),
          SettingsTile(
            icon: PhosphorIconsRegular.translate,
            title: 'Language',
            value: supportedLanguages[settings.language] ?? settings.language,
            onTap: () => _pick(
              title: 'Language',
              options: supportedLanguages,
              selected: settings.language,
              apply: (code) => settings.copyWith(language: code),
            ),
          ),
        ],
      ),
    ];
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
