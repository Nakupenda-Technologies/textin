import 'package:flutter/material.dart';
import '../../data_source/settings_remote_data_source.dart';
import '../../models/user_settings.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tiles.dart';
import 'user_list_screen.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  Future<void> _pickAudience(
    BuildContext context, {
    required String title,
    required Audience selected,
    required ValueChanged<Audience> onPicked,
  }) async {
    final choice = await showSettingsChoice(
      context,
      title: title,
      options: {for (final a in Audience.values) a: a.label},
      selected: selected,
    );
    if (choice != null && choice != selected) onPicked(choice);
  }

  void _open(BuildContext context, UserListKind kind) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => UserListScreen(kind: kind)));

  @override
  Widget build(BuildContext context) {
    return LoadedSettingsPage(
      title: 'Privacy',
      builder: (context, settings, update) => [
        SettingsRow(
          title: 'Who can message me',
          trailing: SettingsValueLink(value: settings.whoCanMessageMe.label),
          onTap: () => _pickAudience(
            context,
            title: 'Who can message me',
            selected: settings.whoCanMessageMe,
            onPicked: (a) => update(settings.copyWith(whoCanMessageMe: a)),
          ),
        ),
        SettingsRow(
          title: 'Who can see my post',
          trailing: SettingsValueLink(value: settings.whoCanSeeMyPost.label),
          onTap: () => _pickAudience(
            context,
            title: 'Who can see my post',
            selected: settings.whoCanSeeMyPost,
            onPicked: (a) => update(settings.copyWith(whoCanSeeMyPost: a)),
          ),
        ),
        SettingsRow(
          title: 'Blocked Accounts',
          trailing: const SettingsValueLink(),
          onTap: () => _open(context, UserListKind.blocked),
        ),
        SettingsRow(
          title: 'Muted Accounts',
          trailing: const SettingsValueLink(),
          onTap: () => _open(context, UserListKind.muted),
        ),
      ],
    );
  }
}
