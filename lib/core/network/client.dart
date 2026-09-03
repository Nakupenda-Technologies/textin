import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../errors/failure.dart';
import '../storage/shared_preferences_store.dart';

class BaseApiClients {
  BaseApiClients({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Map<String, String> _buildHeaders([Map<String, String>? customHeaders]) {
    final token = SharedPreferencesStore.getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?customHeaders,
    };
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
      final response = await _client.get(uri, headers: _buildHeaders(headers));
      return _processResponse(response);
    } on SocketException {
      throw const NetworkFailure();
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnknownFailure(e.toString());
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.post(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw const NetworkFailure();
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnknownFailure(e.toString());
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.patch(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw const NetworkFailure();
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnknownFailure(e.toString());
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.put(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw const NetworkFailure();
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnknownFailure(e.toString());
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client.delete(
        uri,
        headers: _buildHeaders(headers),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw const NetworkFailure();
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnknownFailure(e.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      var message = 'Request failed with status: ${response.statusCode}';
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw ServerFailure(message, statusCode: response.statusCode);
    }
  }

  void close() {
    _client.close();
  }
}
