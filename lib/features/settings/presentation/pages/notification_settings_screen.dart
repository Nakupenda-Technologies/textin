import 'package:flutter/material.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tiles.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadedSettingsPage(
      title: 'Notifications',
      builder: (context, settings, update) => [
        SettingsRow(
          title: 'Push notifications',
          trailing: SettingsSwitch(
            value: settings.pushNotifications,
            onChanged: (v) => update(settings.copyWith(pushNotifications: v)),
          ),
        ),
        SettingsRow(
          title: 'Email notifications',
          trailing: SettingsSwitch(
            value: settings.emailNotifications,
            onChanged: (v) => update(settings.copyWith(emailNotifications: v)),
          ),
        ),
        SettingsRow(
          title: 'Activity notifications',
          subtitle: 'Get notified about new likes, replies, and mentions.',
          trailing: SettingsSwitch(
            value: settings.activityNotifications,
            onChanged: (v) =>
                update(settings.copyWith(activityNotifications: v)),
          ),
        ),
        SettingsRow(
          title: 'Whisper notifications',
          subtitle: 'Alert for voice room invites and speaker request.',
          trailing: SettingsSwitch(
            value: settings.whisperNotifications,
            onChanged: (v) =>
                update(settings.copyWith(whisperNotifications: v)),
          ),
        ),
      ],
    );
  }
}
