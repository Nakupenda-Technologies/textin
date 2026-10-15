import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'shared_pref_keys.dart';
import 'shared_preferences_store.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  static AuthTokens? fromResponse(
    Object? json, {
    String? fallbackRefreshToken,
  }) {
    if (json is! Map<String, dynamic>) return null;
    final source = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final access = source['accessToken'];
    if (access is! String || access.isEmpty) return null;

    final refresh = source['refreshToken'];
    final expiresIn = source['expiresIn'];
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh is String && refresh.isNotEmpty
          ? refresh
          : fallbackRefreshToken,
      expiresAt: expiresIn is num
          ? DateTime.now().add(Duration(seconds: expiresIn.toInt()))
          : null,
    );
  }
}

class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'session_access_token';
  static const _refreshTokenKey = 'session_refresh_token';
  static const _expiresAtKey = 'session_expires_at';
  static const _deviceIdKey = 'session_device_id';

  // Refresh a minute early so requests never race the server-side expiry.
  static const _expiryLeeway = Duration(minutes: 1);

  AuthTokens? _tokens;
  String? _deviceId;

  AuthTokens? get tokens => _tokens;
  String? get accessToken => _tokens?.accessToken;
  String? get refreshToken => _tokens?.refreshToken;
  bool get hasSession => _tokens != null;

  bool get isAccessTokenExpiring {
    final expiresAt = _tokens?.expiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt.subtract(_expiryLeeway));
  }

  Future<void> load() async {
    try {
      final values = await _storage.readAll();
      final access = values[_accessTokenKey];
      final expiresAtMs = int.tryParse(values[_expiresAtKey] ?? '');
      _deviceId = values[_deviceIdKey];
      _tokens = access == null || access.isEmpty
          ? null
          : AuthTokens(
              accessToken: access,
              refreshToken: values[_refreshTokenKey],
              expiresAt: expiresAtMs == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
            );
    } catch (e, st) {
      developer.log(
        'Session restore failed: $e',
        name: 'SessionStore',
        stackTrace: st,
      );
      _tokens = null;
    }
  }

  // The iOS Keychain outlives app uninstalls, so a reinstall would otherwise
  // restore the previous install's session.
  Future<void> resetIfFreshInstall() async {
    if (SharedPreferencesStore.getBool(SharedPrefKeys.hasLaunched) ?? false) {
      return;
    }
    await SharedPreferencesStore.setBool(SharedPrefKeys.hasLaunched, true);
    await _storage.deleteAll();
  }

  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _writeOrDelete(_refreshTokenKey, tokens.refreshToken);
    await _writeOrDelete(
      _expiresAtKey,
      tokens.expiresAt?.millisecondsSinceEpoch.toString(),
    );
  }

  Future<void> clear() async {
    _tokens = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }

  Future<String> deviceId() async {
    final cached = _deviceId;
    if (cached != null && cached.isNotEmpty) return cached;

    final random = Random.secure();
    final generated = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _deviceId = generated;
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  Future<void> _writeOrDelete(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);
}
