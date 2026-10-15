import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/features/settings/data_source/settings_remote_data_source.dart';
import 'package:textin/features/settings/models/user_settings.dart';
import 'package:textin/features/settings/notifier/settings_notifier.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

class _FakeSettingsRepository extends SettingsRepository {
  _FakeSettingsRepository() : super(_NoRemote());

  UserSettings stored = const UserSettings(theme: AppThemePreference.dark);
  bool failUpdates = false;

  @override
  Future<Either<Failure, UserSettings>> fetchSettings() async => Right(stored);

  @override
  Future<Either<Failure, UserSettings>> updateSettings(
    UserSettings settings,
  ) async {
    if (failUpdates) return const Left(ServerFailure('Offline'));
    return Right(stored = settings);
  }
}

class _NoRemote implements SettingsRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('settings are read from their sections', () {
    final settings = UserSettings.fromResponse({
      'success': true,
      'data': {
        'settings': {
          'privacy': {'whoCanMessageMe': 'following'},
          'notification': {
            'pushNotifications': false,
            'emailNotifications': true,
            'whisperNotifications': false,
          },
          'preferences': {'theme': 'dark', 'language': 'sw-KE'},
          'more': {'allowWhisperInvites': false, 'allowSpeakerRequests': true},
        },
      },
    });

    expect(
      settings,
      const UserSettings(
        whoCanMessageMe: MessagePermission.following,
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
      _FakeSettingsRepository(),
      onThemeChanged: themes.add,
    );
    addTearDown(notifier.dispose);

    await notifier.load();

    expect(notifier.state.status, SettingsStatus.loaded);
    expect(themes, [AppThemePreference.dark]);
  });

  test('a failed update rolls the change back', () async {
    final repository = _FakeSettingsRepository()..failUpdates = true;
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
