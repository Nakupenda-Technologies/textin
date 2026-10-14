import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';

import '../../../core/errors/failure.dart';
import '../../../core/storage/session_store.dart';
import '../../../core/storage/shared_pref_keys.dart';
import '../../../core/storage/shared_preferences_store.dart';
import '../data_source/auth_remote_data_source.dart';
import '../models/auth_user.dart';
import '../models/current_item.dart';
import '../models/registration_details.dart';
import '../models/registration_step.dart';

class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource remote,
    required SessionStore session,
  }) : _remote = remote,
       _session = session;

  final AuthRemoteDataSource _remote;
  final SessionStore _session;

  static const _personalFlowKey = 'onboarding_personal';

  bool get hasSession => _session.hasSession;

  String? get pendingProcessId {
    final id = SharedPreferencesStore.getString(
      SharedPrefKeys.registrationProcessId,
    );
    return id == null || id.isEmpty ? null : id;
  }

  AuthUser? get cachedUser {
    final raw = SharedPreferencesStore.getString(SharedPrefKeys.cachedUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<Either<Failure, AuthUser>> signIn({
    required String identifier,
    required String password,
  }) => _guard(() async {
    await _session.clear();
    final tokens = await _remote.login(
      identifier: identifier,
      password: password,
    );
    await _session.save(tokens);
    try {
      final user = await _loadUser();
      await _clearProcessId();
      return user;
    } on Failure {
      await _session.clear();
      rethrow;
    }
  });

  Future<Either<Failure, AuthUser>> refreshUser() => _guard(_loadUser);

  Future<void> signOut() async {
    await _session.clear();
    await SharedPreferencesStore.remove(SharedPrefKeys.cachedUser);
    await _clearProcessId();
  }

  Future<Either<Failure, RegistrationStep?>> startRegistration() =>
      _guard(() async {
        final previous = pendingProcessId;
        if (previous != null) {
          try {
            await _remote.deleteProcess(previous);
          } on Failure catch (failure) {
            developer.log(
              'Stale registration not deleted: ${failure.message}',
              name: 'AuthRepository',
            );
          }
          await _clearProcessId();
        }

        final tracker = await _remote.startProcess(
          flowKey: _personalFlowKey,
          deviceId: await _session.deviceId(),
        );
        await SharedPreferencesStore.setString(
          SharedPrefKeys.registrationProcessId,
          tracker.processId,
        );
        final result = await _remote.submitStep(
          tracker.processId,
          RegistrationStep.accountType,
          {'accountType': 'personal'},
        );
        return result.step.nextStep ?? RegistrationStep.basicInfo;
      });

  Future<Either<Failure, RegistrationStep?>> resumeRegistration() =>
      _guard(() async {
        final processId = pendingProcessId;
        if (processId == null) return null;

        final tracker = await _remote.getProcess(processId);
        if (tracker.isExpired || tracker.flowKey != _personalFlowKey) {
          await _clearProcessId();
          return null;
        }
        return tracker.step.nextStep;
      });

  Future<Either<Failure, bool>> isUsernameAvailable(String username) =>
      _guard(() => _remote.isUsernameAvailable(username));

  Future<Either<Failure, RegistrationStep?>> submitBasicInfo(BasicInfo info) =>
      _submit(RegistrationStep.basicInfo, info.toPayload());

  Future<Either<Failure, RegistrationStep?>> submitPassword(String password) =>
      _guard(() async {
        final processId = _requireProcessId();
        final result = await _remote.submitStep(
          processId,
          RegistrationStep.passwordSetup,
          {'password': password},
        );
        if (result.tokens case final tokens?) await _session.save(tokens);
        return result.step.nextStep;
      });

  Future<Either<Failure, RegistrationStep?>> submitAgeGender({
    required DateTime dateOfBirth,
    required Gender gender,
  }) => _guard(() async {
    final processId = _requireProcessId();
    var result = await _remote
        .submitStep(processId, RegistrationStep.ageGender, {
          'dateOfBirth': DateTime.utc(
            dateOfBirth.year,
            dateOfBirth.month,
            dateOfBirth.day,
          ).toIso8601String(),
          'gender': gender.apiValue,
        });

    // Textin has no theme or creator settings, so these Nakupenda steps are
    // answered with the same defaults the parent app sends.
    if (result.step.nextStep == RegistrationStep.themeSelection) {
      result = await _remote.submitStep(
        processId,
        RegistrationStep.themeSelection,
        {'skip': true},
      );
    }
    if (result.step.nextStep == RegistrationStep.creatorMode) {
      result = await _remote.submitStep(
        processId,
        RegistrationStep.creatorMode,
        {'creatorMode': false},
      );
    }
    return result.step.nextStep;
  });

  Future<Either<Failure, List<CurrentItem>>> fetchCurrents() =>
      _guard(_remote.fetchCurrents);

  Future<Either<Failure, AuthUser>> completeRegistration(
    List<String> currentIds,
  ) => _guard(() async {
    final processId = _requireProcessId();
    await _remote.submitStep(processId, RegistrationStep.currents, {
      'currentIds': currentIds,
      'skip': false,
    });
    await _remote.completeProcess(processId);
    await _clearProcessId();
    return _loadUser();
  });

  Future<Either<Failure, RegistrationStep?>> _submit(
    RegistrationStep step,
    Map<String, dynamic> payload,
  ) => _guard(() async {
    final result = await _remote.submitStep(_requireProcessId(), step, payload);
    return result.step.nextStep;
  });

  Future<AuthUser> _loadUser() async {
    final user = await _remote.fetchMe();
    await SharedPreferencesStore.setString(
      SharedPrefKeys.cachedUser,
      jsonEncode(user.toJson()),
    );
    return user;
  }

  String _requireProcessId() =>
      pendingProcessId ??
      (throw const UnknownFailure(
        'Your sign up session has ended. Please start again.',
      ));

  Future<void> _clearProcessId() =>
      SharedPreferencesStore.remove(SharedPrefKeys.registrationProcessId);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected auth error: $error',
        name: 'AuthRepository',
        stackTrace: stackTrace,
      );
      return const Left(UnknownFailure());
    }
  }
}
