import 'package:flutter/material.dart';
import '../../models/user_settings.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tiles.dart';

class PreferenceSettingsScreen extends StatelessWidget {
  const PreferenceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadedSettingsPage(
      title: 'Preferences',
      builder: (context, settings, update) => [
        SettingsRow(
          title: 'Language',
          trailing: SettingsDropdownPill<String>(
            options: supportedLanguages,
            selected: settings.language,
            onSelected: (code) => update(settings.copyWith(language: code)),
          ),
        ),
        SettingsRow(
          title: 'Theme',
          trailing: SettingsSegmented<AppThemePreference>(
            options: {
              for (final t in [
                AppThemePreference.light,
                AppThemePreference.dark,
                AppThemePreference.system,
              ])
                t: t.label,
            },
            selected: settings.theme,
            onSelected: (t) => update(settings.copyWith(theme: t)),
          ),
        ),
      ],
    );
  }
}
