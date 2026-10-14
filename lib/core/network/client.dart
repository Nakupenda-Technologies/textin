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

  Future<dynamic> upload(
    String endpoint, {
    required String field,
    required String filePath,
    required String contentType,
  }) {
    final uri = Uri.parse('$baseUrl$endpoint');
    return _dispatch(
      (token) async => http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers(token, json: false))
        ..files.add(
          await http.MultipartFile.fromPath(
            field,
            filePath,
            contentType: http.MediaType.parse(contentType),
          ),
        ),
    );
  }

  Future<dynamic> _send(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    return _dispatch((token) async {
      final request = http.Request(method, uri)
        ..headers.addAll({..._headers(token), ...?headers});
      if (body != null) request.body = jsonEncode(body);
      return request;
    });
  }

  Map<String, String> _headers(String? token, {bool json = true}) => {
    if (json) 'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> _dispatch(
    Future<http.BaseRequest> Function(String? token) build,
  ) async {
    final token = await session?.accessTokenForRequest();
    var response = await _execute(await build(token));

    final activeSession = session;
    if (response.statusCode == 401 &&
        activeSession != null &&
        token != null &&
        activeSession.canRefresh) {
      await activeSession.refresh();
      response = await _execute(await build(activeSession.store.accessToken));
      if (response.statusCode == 401) {
        await activeSession.expire();
        throw const SessionExpiredFailure();
      }
    }

    return _decode(response);
  }

  Future<http.Response> _execute(http.BaseRequest request) async {
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
