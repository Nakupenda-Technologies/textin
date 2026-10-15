import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/settings/models/user_settings.dart';
import 'package:textin/features/settings/notifier/settings_notifier.dart';

import '../../helpers/fake_settings_repository.dart';

void main() {
  test('settings are read from their sections', () {
    final settings = UserSettings.fromResponse({
      'success': true,
      'data': {
        'settings': {
          'privacy': {
            'whoCanMessageMe': 'following',
            'whoCanSeeMyPost': 'following',
          },
          'notification': {
            'pushNotifications': false,
            'emailNotifications': true,
            'activityNotifications': false,
            'whisperNotifications': false,
          },
          'preferences': {'theme': 'dark', 'language': 'sw-KE'},
          'more': {
            'allowWhisperInvites': false,
            'allowSpeakerRequests': true,
            'allowSnippetFromVoice': false,
            'showPostsInDiscovery': false,
            'allowContentInCurrents': true,
          },
        },
      },
    });

    expect(
      settings,
      const UserSettings(
        whoCanMessageMe: Audience.following,
        whoCanSeeMyPost: Audience.following,
        activityNotifications: false,
        allowSnippetFromVoice: false,
        showPostsInDiscovery: false,
        pushNotifications: false,
        whisperNotifications: false,
        allowWhisperInvites: false,
        theme: AppThemePreference.dark,
        language: 'sw-KE',
      ),
    );
  });

  test('loading applies the saved theme', () async {
    final themes = <AppThemePreference>[];
    final notifier = SettingsNotifier(
      FakeSettingsRepository(
        stored: const UserSettings(theme: AppThemePreference.dark),
      ),
      onThemeChanged: themes.add,
    );
    addTearDown(notifier.dispose);

    await notifier.load();

    expect(notifier.state.status, SettingsStatus.loaded);
    expect(themes, [AppThemePreference.dark]);
  });

  test('a failed update rolls the change back', () async {
    final repository = FakeSettingsRepository(failUpdates: true);
    final notifier = SettingsNotifier(repository, onThemeChanged: (_) {});
    addTearDown(notifier.dispose);
    await notifier.load();

    await notifier.update(
      notifier.state.settings.copyWith(pushNotifications: false),
    );

    expect(notifier.state.settings.pushNotifications, isTrue);
    expect(notifier.state.errorMessage, 'Offline');
  });
}
