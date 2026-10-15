import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../data_source/settings_remote_data_source.dart';
import '../../models/user_settings.dart';
import '../../notifier/settings_notifier.dart';
import '../../repository/settings_repository.dart';
import '../widgets/account_dialogs.dart';
import '../widgets/settings_tiles.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'user_list_screen.dart';

typedef _Item = ({String label, Widget child});

class _Section {
  const _Section(this.heading, this.items);

  final Widget heading;
  final List<_Item> items;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsNotifierProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _update(UserSettings settings) =>
      ref.read(settingsNotifierProvider.notifier).update(settings);

  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _deactivate() async {
    if (!await confirmDeactivation(context)) return;
    final result = await locator<SettingsRepository>().deactivateAccount();
    result.fold(
      _showFailure,
      (_) => signOutToLogin(
        ref,
        message: 'Account deactivated. Sign in again to reactivate it.',
      ),
    );
  }

  Future<void> _delete() async {
    final password = await askPasswordToDelete(context);
    if (password == null) return;
    final result = await locator<SettingsRepository>().deleteAccount(password);
    result.fold(
      _showFailure,
      (_) => signOutToLogin(ref, message: 'Your account has been deleted.'),
    );
  }

  void _showFailure(Failure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _pickAudience({
    required String title,
    required Audience selected,
    required UserSettings Function(Audience choice) apply,
  }) async {
    final choice = await showSettingsChoice(
      context,
      title: title,
      options: {for (final a in Audience.values) a: a.label},
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
    final state = ref.watch(settingsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _Header(),
            const SizedBox(height: 16),
            _SearchField(
              controller: _search,
              onChanged: (q) => setState(() => _query = q.trim().toLowerCase()),
            ),
            ..._buildBody(state),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(SettingsState state) {
    if (state.status == SettingsStatus.loading) {
      return const [
        SizedBox(height: 24),
        AppShimmer(
          child: Column(
            children: [
              ShimmerBlock(height: 24, width: 120),
              SizedBox(height: 16),
              ShimmerBlock(height: 280, radius: 16),
            ],
          ),
        ),
      ];
    }
    if (state.status == SettingsStatus.error) {
      return [
        const SizedBox(height: 32),
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

    final visible = [
      for (final section in _sections(state.settings))
        if (section.items.where(_matches).toList() case final items
            when items.isNotEmpty)
          [section.heading, for (final item in items) item.child],
    ];
    if (visible.isEmpty) {
      return [
        const SizedBox(height: 40),
        Center(
          child: Text(
            'No settings match "${_search.text.trim()}"',
            style: AppTextStyle.bodySecondary,
          ),
        ),
      ];
    }
    return [for (final widgets in visible) ...widgets];
  }

  bool _matches(_Item item) =>
      _query.isEmpty || item.label.toLowerCase().contains(_query);

  List<_Section> _sections(UserSettings settings) {
    final email = ref.watch(currentUserProvider)?.email;

    return [
      _Section(const SettingsHeading('Account'), [
        (
          label: 'Email',
          child: SettingsRow(
            title: 'Email',
            subtitle: email,
            trailing: SettingsPillButton(
              label: 'Edit',
              onPressed: () => _open(const ChangeEmailScreen()),
            ),
          ),
        ),
        (
          label: 'Password',
          child: SettingsRow(
            title: 'Password',
            subtitle: List.filled(14, '*').join(' '),
            trailing: SettingsPillButton(
              label: 'Change',
              onPressed: () => _open(const ChangePasswordScreen()),
            ),
          ),
        ),
        (
          label: 'Deactivate my account',
          child: SettingsRow(
            title: 'Deactivate my account',
            subtitle: 'Hide your profile and content temporarily.',
            trailing: SettingsPillButton(
              label: 'Deactivate',
              onPressed: _deactivate,
            ),
          ),
        ),
        (
          label: 'Delete my account',
          child: SettingsRow(
            title: 'Delete my account',
            subtitle:
                'Permanently delete your data and profile. '
                'This cannot be undone.',
            trailing: SettingsPillButton(
              label: 'Delete',
              destructive: true,
              onPressed: _delete,
            ),
          ),
        ),
      ]),
      _Section(const SettingsHeading('Privacy', accent: false), [
        (
          label: 'Who can message me',
          child: SettingsRow(
            title: 'Who can message me',
            trailing: SettingsValueLink(value: settings.whoCanMessageMe.label),
            onTap: () => _pickAudience(
              title: 'Who can message me',
              selected: settings.whoCanMessageMe,
              apply: (a) => settings.copyWith(whoCanMessageMe: a),
            ),
          ),
        ),
        (
          label: 'Who can see my post',
          child: SettingsRow(
            title: 'Who can see my post',
            trailing: SettingsValueLink(value: settings.whoCanSeeMyPost.label),
            onTap: () => _pickAudience(
              title: 'Who can see my post',
              selected: settings.whoCanSeeMyPost,
              apply: (a) => settings.copyWith(whoCanSeeMyPost: a),
            ),
          ),
        ),
        (
          label: 'Blocked Accounts',
          child: SettingsRow(
            title: 'Blocked Accounts',
            trailing: const SettingsValueLink(),
            onTap: () =>
                _open(const UserListScreen(kind: UserListKind.blocked)),
          ),
        ),
        (
          label: 'Muted Accounts',
          child: SettingsRow(
            title: 'Muted Accounts',
            trailing: const SettingsValueLink(),
            onTap: () => _open(const UserListScreen(kind: UserListKind.muted)),
          ),
        ),
      ]),
      _Section(const SettingsHeading('Notification'), [
        (
          label: 'Push notifications',
          child: SettingsRow(
            title: 'Push notifications',
            trailing: SettingsSwitch(
              value: settings.pushNotifications,
              onChanged: (v) =>
                  _update(settings.copyWith(pushNotifications: v)),
            ),
          ),
        ),
        (
          label: 'Email notifications',
          child: SettingsRow(
            title: 'Email notifications',
            trailing: SettingsSwitch(
              value: settings.emailNotifications,
              onChanged: (v) =>
                  _update(settings.copyWith(emailNotifications: v)),
            ),
          ),
        ),
        (
          label: 'Activity notifications',
          child: SettingsRow(
            title: 'Activity notifications',
            subtitle: 'Get notified about new likes, replies, and mentions.',
            trailing: SettingsSwitch(
              value: settings.activityNotifications,
              onChanged: (v) =>
                  _update(settings.copyWith(activityNotifications: v)),
            ),
          ),
        ),
        (
          label: 'Whisper notifications',
          child: SettingsRow(
            title: 'Whisper notifications',
            subtitle: 'Alert for voice room invites and speaker request.',
            trailing: SettingsSwitch(
              value: settings.whisperNotifications,
              onChanged: (v) =>
                  _update(settings.copyWith(whisperNotifications: v)),
            ),
          ),
        ),
      ]),
      _Section(const SettingsHeading('Preferences'), [
        (
          label: 'Language',
          child: SettingsRow(
            title: 'Language',
            trailing: SettingsDropdownPill<String>(
              options: supportedLanguages,
              selected: settings.language,
              onSelected: (code) => _update(settings.copyWith(language: code)),
            ),
          ),
        ),
        (
          label: 'Theme',
          child: SettingsRow(
            title: 'Theme',
            trailing: SettingsSegmented<AppThemePreference>(
              options: {
                AppThemePreference.light: AppThemePreference.light.label,
                AppThemePreference.dark: AppThemePreference.dark.label,
                AppThemePreference.system: AppThemePreference.system.label,
              },
              selected: settings.theme,
              onSelected: (t) => _update(settings.copyWith(theme: t)),
            ),
          ),
        ),
      ]),
      _Section(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsHeading('More'),
            SettingsHeading('Whispers', accent: false, large: false),
          ],
        ),
        [
          (
            label: 'Allow whispers invites',
            child: SettingsRow(
              title: 'Allow whispers invites',
              trailing: SettingsSwitch(
                value: settings.allowWhisperInvites,
                onChanged: (v) =>
                    _update(settings.copyWith(allowWhisperInvites: v)),
              ),
            ),
          ),
          (
            label: 'Allow speaker requests',
            child: SettingsRow(
              title: 'Allow speaker requests',
              trailing: SettingsSwitch(
                value: settings.allowSpeakerRequests,
                onChanged: (v) =>
                    _update(settings.copyWith(allowSpeakerRequests: v)),
              ),
            ),
          ),
          (
            label: 'Allow snippet creation from my voice',
            child: SettingsRow(
              title: 'Allow snippet creation from my voice',
              subtitle:
                  'Let others create short clips from your whisper '
                  'contribution',
              trailing: SettingsSwitch(
                value: settings.allowSnippetFromVoice,
                onChanged: (v) =>
                    _update(settings.copyWith(allowSnippetFromVoice: v)),
              ),
            ),
          ),
        ],
      ),
      _Section(const SettingsHeading('Content & Discovery', large: false), [
        (
          label: 'Show my posts in discovery',
          child: SettingsRow(
            title: 'Show my posts in discovery',
            trailing: SettingsSwitch(
              value: settings.showPostsInDiscovery,
              onChanged: (v) =>
                  _update(settings.copyWith(showPostsInDiscovery: v)),
            ),
          ),
        ),
        (
          label: 'Allow my content in Currents',
          child: SettingsRow(
            title: 'Allow my content in Currents',
            trailing: SettingsSwitch(
              value: settings.allowContentInCurrents,
              onChanged: (v) =>
                  _update(settings.copyWith(allowContentInCurrents: v)),
            ),
          ),
        ),
      ]),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
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
                    color: cs.onSurface,
                    semanticLabel: 'Back',
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
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
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search for settings',
        hintStyle: TextStyle(fontSize: 13, color: muted),
        prefixIcon: Icon(
          PhosphorIconsRegular.magnifyingGlass,
          size: 18,
          color: muted,
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
