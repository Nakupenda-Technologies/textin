import 'package:flutter/material.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tiles.dart';

class WhisperSettingsScreen extends StatelessWidget {
  const WhisperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadedSettingsPage(
      title: 'Whispers',
      builder: (context, settings, update) => [
        SettingsRow(
          title: 'Allow whispers invites',
          trailing: SettingsSwitch(
            value: settings.allowWhisperInvites,
            onChanged: (v) => update(settings.copyWith(allowWhisperInvites: v)),
          ),
        ),
        SettingsRow(
          title: 'Allow speaker requests',
          trailing: SettingsSwitch(
            value: settings.allowSpeakerRequests,
            onChanged: (v) =>
                update(settings.copyWith(allowSpeakerRequests: v)),
          ),
        ),
        SettingsRow(
          title: 'Allow snippet creation from my voice',
          subtitle:
              'Let others create short clips from your whisper contribution',
          trailing: SettingsSwitch(
            value: settings.allowSnippetFromVoice,
            onChanged: (v) =>
                update(settings.copyWith(allowSnippetFromVoice: v)),
          ),
        ),
      ],
    );
  }
}
