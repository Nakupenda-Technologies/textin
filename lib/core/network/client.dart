import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/failure.dart';
import 'session_manager.dart';

class BaseApiClients {
  BaseApiClients({
    required this.baseUrl,
    this.session,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final SessionManager? session;
  final http.Client _client;
  final Duration timeout;

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) => _send(
    'GET',
    endpoint,
    headers: headers,
    queryParameters: queryParameters,
  );

  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) => _send('POST', endpoint, headers: headers, body: body);

  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) => _send('PATCH', endpoint, headers: headers, body: body);

  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) => _send('PUT', endpoint, headers: headers, body: body);

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) => _send('DELETE', endpoint, headers: headers, body: body);

  Future<dynamic> _send(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    final token = await session?.accessTokenForRequest();
    var response = await _request(method, uri, headers, body, token);

    final activeSession = session;
    if (response.statusCode == 401 &&
        activeSession != null &&
        token != null &&
        activeSession.canRefresh) {
      await activeSession.refresh();
      response = await _request(
        method,
        uri,
        headers,
        body,
        activeSession.store.accessToken,
      );
      if (response.statusCode == 401) {
        await activeSession.expire();
        throw const SessionExpiredFailure();
      }
    }

    return _decode(response);
  }

  Future<http.Response> _request(
    String method,
    Uri uri,
    Map<String, String>? headers,
    Object? body,
    String? token,
  ) async {
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        ...?headers,
      });
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on SocketException {
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const TimeoutFailure();
    }
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;
    final Object? decoded = _tryJson(response.body);

    if (status >= 200 && status < 300) return decoded;

    throw ServerFailure(_serverMessage(decoded) ?? '', statusCode: status);
  }

  Object? _tryJson(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String? _serverMessage(Object? decoded) {
    if (decoded is! Map) return null;
    final message = decoded['message'] ?? decoded['error'];
    return switch (message) {
      String text when text.trim().isNotEmpty => text,
      List items when items.isNotEmpty => items.first.toString(),
      _ => null,
    };
  }

  void close() => _client.close();
}
