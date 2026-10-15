import 'package:flutter_test/flutter_test.dart';
import 'package:textin/features/settings/data_source/settings_remote_data_source.dart';
import 'package:textin/features/settings/repository/settings_repository.dart';

class _RecordingRemote implements SettingsRemoteDataSource {
  final uploads = <(String, String)>[];
  Map<String, dynamic>? profileChanges;

  @override
  Future<String> uploadProfilePicture(
    String filePath,
    String contentType,
  ) async {
    uploads.add((filePath, contentType));
    return 'https://cdn.test/avatar.png';
  }

  @override
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> changes,
  ) async => profileChanges = changes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a new picture is uploaded before the profile is saved', () async {
    final remote = _RecordingRemote();

    await SettingsRepository(remote).updateProfile(
      firstName: 'Ada',
      lastName: 'Obi',
      bio: 'Hi',
      newPicturePath: '/tmp/me.png',
    );

    expect(remote.uploads, [('/tmp/me.png', 'image/png')]);
    expect(remote.profileChanges, {
      'firstName': 'Ada',
      'lastName': 'Obi',
      'bio': 'Hi',
      'profilePicture': 'https://cdn.test/avatar.png',
    });
  });

  test('the picture is left alone when none was picked', () async {
    final remote = _RecordingRemote();

    await SettingsRepository(
      remote,
    ).updateProfile(firstName: 'Ada', lastName: 'Obi', bio: '');

    expect(remote.uploads, isEmpty);
    expect(remote.profileChanges?.containsKey('profilePicture'), isFalse);
  });
}
