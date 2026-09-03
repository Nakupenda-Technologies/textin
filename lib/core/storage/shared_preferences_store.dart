import 'package:shared_preferences/shared_preferences.dart';
import 'shared_pref_keys.dart';

class SharedPreferencesStore {
  SharedPreferencesStore._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get instance {
    if (_prefs == null) {
      throw StateError(
        'SharedPreferencesStore must be initialized by calling init() first.',
      );
    }
    return _prefs!;
  }

  static Future<bool> setString(String key, String value) async {
    return instance.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return instance.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<bool> remove(String key) async {
    return _prefs != null ? instance.remove(key) : false;
  }

  static Future<bool> clear() async {
    return _prefs != null ? instance.clear() : false;
  }

  // Convenience helpers
  static String? getAuthToken() => getString(SharedPrefKeys.token);
  static Future<bool> setAuthToken(String token) =>
      setString(SharedPrefKeys.token, token);
  static Future<bool> removeAuthToken() => remove(SharedPrefKeys.token);
}
