import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/network/client.dart';
import 'package:textin/core/network/session_manager.dart';
import 'package:textin/core/storage/session_store.dart';

const _base = 'https://api.test';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late SessionStore store;
  late int refreshCalls;
  late int expiredCalls;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    store = SessionStore();
    await store.load();
    refreshCalls = 0;
    expiredCalls = 0;
  });

  BaseApiClients buildClient(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final mock = MockClient(handler);
    final session = SessionManager(
      store: store,
      authBaseUrl: _base,
      client: mock,
    )..onSessionExpired = () => expiredCalls++;
    return BaseApiClients(baseUrl: _base, session: session, client: mock);
  }

  test('refreshes once on 401 and retries with the new token', () async {
    await store.save(
      const AuthTokens(accessToken: 'old', refreshToken: 'refresh-1'),
    );
    final client = buildClient((request) async {
      if (request.url.path == '/auth/refresh') {
        refreshCalls++;
        return _json({
          'accessToken': 'new',
          'refreshToken': 'refresh-2',
          'expiresIn': 900,
        }, 200);
      }
      final auth = request.headers['Authorization'];
      return auth == 'Bearer new'
          ? _json({'ok': true}, 200)
          : _json({'message': 'Unauthorized'}, 401);
    });

    final results = await Future.wait([
      client.get('/users/me'),
      client.get('/users/me'),
    ]);

    expect(results, everyElement({'ok': true}));
    expect(refreshCalls, 1);
    expect(store.accessToken, 'new');
    expect(store.refreshToken, 'refresh-2');
  });

  test('ends the session when the refresh token is rejected', () async {
    await store.save(
      const AuthTokens(accessToken: 'old', refreshToken: 'refresh-1'),
    );
    final client = buildClient((request) async {
      if (request.url.path == '/auth/refresh') {
        return _json({'message': 'Invalid refresh token'}, 401);
      }
      return _json({'message': 'Unauthorized'}, 401);
    });

    await expectLater(
      client.get('/users/me'),
      throwsA(isA<SessionExpiredFailure>()),
    );
    expect(store.hasSession, isFalse);
    expect(expiredCalls, 1);
  });

  test('keeps the session when refresh fails for a server reason', () async {
    await store.save(
      const AuthTokens(accessToken: 'old', refreshToken: 'refresh-1'),
    );
    final client = buildClient((request) async {
      if (request.url.path == '/auth/refresh') {
        return http.Response('Bad gateway', 502);
      }
      return _json({'message': 'Unauthorized'}, 401);
    });

    await expectLater(client.get('/users/me'), throwsA(isA<ServerFailure>()));
    expect(store.hasSession, isTrue);
    expect(expiredCalls, 0);
  });

  test('a 401 without a session is returned as a normal failure', () async {
    final client = buildClient(
      (_) async => _json({'message': 'Invalid credentials'}, 401),
    );

    await expectLater(
      client.post('/auth/login', body: {'identifier': 'a', 'password': 'b'}),
      throwsA(
        isA<ServerFailure>()
            .having((f) => f.message, 'message', 'Invalid credentials')
            .having((f) => f.statusCode, 'statusCode', 401),
      ),
    );
    expect(expiredCalls, 0);
  });

  test('reads the first validation message from a list', () async {
    final client = buildClient(
      (_) async => _json({
        'message': ['email must be an email', 'username is too short'],
      }, 400),
    );

    await expectLater(
      client.post('/process-tracker/x/step'),
      throwsA(
        isA<ServerFailure>().having(
          (f) => f.message,
          'message',
          'email must be an email',
        ),
      ),
    );
  });

  test('maps connection errors to a network failure', () async {
    final client = buildClient(
      (_) async => throw http.ClientException('Connection closed'),
    );

    await expectLater(client.get('/currents'), throwsA(isA<NetworkFailure>()));
  });
}
