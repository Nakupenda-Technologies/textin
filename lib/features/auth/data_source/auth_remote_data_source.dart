import 'package:flutter/foundation.dart';

import '../../../config/constants/endpoints.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/client.dart';
import '../../../core/storage/session_store.dart';
import '../models/auth_user.dart';
import '../models/current_item.dart';
import '../models/registration_step.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokens> login({
    required String identifier,
    required String password,
  });

  Future<AuthUser> fetchMe();

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<ProcessTracker> startProcess({
    required String flowKey,
    required String deviceId,
  });

  Future<ProcessTracker> getProcess(String processId);

  Future<({StepResult step, AuthTokens? tokens})> submitStep(
    String processId,
    RegistrationStep step,
    Map<String, dynamic> payload,
  );

  Future<void> deleteProcess(String processId);

  Future<void> completeProcess(String processId);

  Future<bool> isUsernameAvailable(String username);

  Future<List<CurrentItem>> fetchCurrents();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final BaseApiClients _client;

  static const _invalidResponse = UnknownFailure(
    "We couldn't read the server's response. Please try again.",
  );

  @override
  Future<AuthTokens> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _client.post(
      Endpoints.login,
      headers: {'x-client-platform': _platform},
      body: {'identifier': identifier, 'password': password},
    );
    return AuthTokens.fromResponse(response) ?? (throw _invalidResponse);
  }

  @override
  Future<AuthUser> fetchMe() async {
    final response = await _client.get(Endpoints.me);
    return AuthUser.fromJson(response) ?? (throw _invalidResponse);
  }

  @override
  Future<void> requestPasswordReset(String email) =>
      _client.post(Endpoints.forgotPassword, body: {'email': email});

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _client.post(
    Endpoints.resetPassword,
    body: {'email': email, 'code': code, 'newPassword': newPassword},
  );

  @override
  Future<ProcessTracker> startProcess({
    required String flowKey,
    required String deviceId,
  }) async {
    final response = await _client.post(
      Endpoints.processTrackerSetup,
      headers: {'X-Device-Id': deviceId},
      body: {'flowKey': flowKey},
    );
    return ProcessTracker.fromJson(response) ?? (throw _invalidResponse);
  }

  @override
  Future<ProcessTracker> getProcess(String processId) async {
    final response = await _client.get(Endpoints.processTracker(processId));
    return ProcessTracker.fromJson(response) ?? (throw _invalidResponse);
  }

  @override
  Future<({StepResult step, AuthTokens? tokens})> submitStep(
    String processId,
    RegistrationStep step,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.patch(
      Endpoints.processTrackerStep(processId),
      body: {'step': step.key, 'payload': payload, 'isCompleted': true},
    );
    return (
      step: StepResult.fromJson(response),
      tokens: AuthTokens.fromResponse(response),
    );
  }

  @override
  Future<void> deleteProcess(String processId) =>
      _client.delete(Endpoints.processTracker(processId));

  @override
  Future<void> completeProcess(String processId) => _client.post(
    Endpoints.processTrackerComplete(processId),
    body: const <String, dynamic>{},
  );

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _client.get(
      Endpoints.validateUsername,
      queryParameters: {'username': username},
    );
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic> && data['available'] is bool) {
        return data['available'] as bool;
      }
    }
    throw _invalidResponse;
  }

  @override
  Future<List<CurrentItem>> fetchCurrents() async {
    final response = await _client.get(Endpoints.currents);
    final data = response is Map<String, dynamic> ? response['data'] : response;
    if (data is! List) throw _invalidResponse;
    return data.map(CurrentItem.fromJson).whereType<CurrentItem>().toList();
  }

  String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => 'web',
  };
}
