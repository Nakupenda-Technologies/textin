import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/constants/endpoints.dart';
import '../errors/failure.dart';
import '../storage/session_store.dart';

class SessionManager {
  SessionManager({
    required this.store,
    required String authBaseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _authBaseUrl = authBaseUrl,
       _client = client ?? http.Client();

  final SessionStore store;
  final String _authBaseUrl;
  final http.Client _client;
  final Duration timeout;

  void Function()? onSessionExpired;

  Future<void>? _inFlightRefresh;

  bool get canRefresh => (store.refreshToken ?? '').isNotEmpty;

  Future<String?> accessTokenForRequest() async {
    if (store.isAccessTokenExpiring && canRefresh) {
      try {
        await refresh();
      } on SessionExpiredFailure {
        return null;
      } on Failure {
        // A transient refresh failure keeps the current token; the request
        // gets a 401 retry if the server really rejects it.
      }
    }
    return store.accessToken;
  }

  Future<void> refresh() => _inFlightRefresh ??= _refresh().whenComplete(
    () => _inFlightRefresh = null,
  );

  Future<void> _refresh() async {
    final refreshToken = store.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await expire();
      throw const SessionExpiredFailure();
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_authBaseUrl${Endpoints.refreshToken}'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(timeout);
    } on SocketException {
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const TimeoutFailure();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Object? body;
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        body = null;
      }
      final tokens = AuthTokens.fromResponse(
        body,
        fallbackRefreshToken: refreshToken,
      );
      if (tokens == null) {
        throw const UnknownFailure();
      }
      await store.save(tokens);
      return;
    }

    if (const {400, 401, 403}.contains(response.statusCode)) {
      await expire();
      throw const SessionExpiredFailure();
    }

    throw ServerFailure(
      'Something went wrong on our side. Please try again.',
      statusCode: response.statusCode,
    );
  }

  Future<void> expire() async {
    final hadSession = store.hasSession;
    await store.clear();
    if (hadSession) onSessionExpired?.call();
  }
}
