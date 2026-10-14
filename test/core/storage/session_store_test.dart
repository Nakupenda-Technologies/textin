import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/storage/session_store.dart';
import 'package:textin/core/storage/shared_pref_keys.dart';
import 'package:textin/core/storage/shared_preferences_store.dart';

void main() {
  const storedSession = {'session_access_token': 'stale-token'};

  Future<SessionStore> restore({required bool hasLaunched}) async {
    SharedPreferences.setMockInitialValues({
      if (hasLaunched) SharedPrefKeys.hasLaunched: true,
    });
    FlutterSecureStorage.setMockInitialValues(Map.of(storedSession));
    await SharedPreferencesStore.init();

    final session = SessionStore();
    await session.resetIfFreshInstall();
    await session.load();
    return session;
  }

  test('drops a keychain session left over from a previous install', () async {
    final session = await restore(hasLaunched: false);

    expect(session.hasSession, isFalse);
    expect(SharedPreferencesStore.getBool(SharedPrefKeys.hasLaunched), isTrue);
  });

  test('keeps the session on later launches', () async {
    final session = await restore(hasLaunched: true);

    expect(session.accessToken, 'stale-token');
  });
}
