import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/storage/session_store.dart';
import 'package:textin/core/storage/shared_pref_keys.dart';
import 'package:textin/features/auth/models/registration_details.dart';
import 'package:textin/features/auth/models/registration_step.dart';
import 'package:textin/features/auth/repository/auth_repository.dart';
import 'package:textin/services/local_storage_service.dart';

import 'fake_auth_remote_data_source.dart';

void main() {
  late FakeAuthRemoteDataSource remote;
  late SessionStore session;
  late AuthRepository repository;

  Future<void> setUpWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorageService.init();
    remote = FakeAuthRemoteDataSource();
    session = SessionStore();
    await session.load();
    repository = AuthRepository(remote: remote, session: session);
  }

  group('signIn', () {
    test(
      'saves the session, caches the user and drops stale sign ups',
      () async {
        await setUpWith({SharedPrefKeys.registrationProcessId: 'old-process'});

        final result = await repository.signIn(
          identifier: 'slim',
          password: 'secret',
        );

        expect(result.isRight(), isTrue);
        expect(session.accessToken, 'access');
        expect(repository.cachedUser, FakeAuthRemoteDataSource.user);
        expect(repository.pendingProcessId, isNull);
      },
    );

    test('returns the server failure for wrong credentials', () async {
      await setUpWith({});
      remote.loginFailure = const ServerFailure(
        'Invalid credentials',
        statusCode: 401,
      );

      final result = await repository.signIn(
        identifier: 'slim',
        password: 'wrong',
      );

      expect(
        result.fold((failure) => failure.message, (_) => null),
        'Invalid credentials',
      );
      expect(session.hasSession, isFalse);
    });

    test(
      'does not keep a half signed in session when the profile fails',
      () async {
        await setUpWith({});
        remote.fetchMeFailure = const NetworkFailure();

        final result = await repository.signIn(
          identifier: 'slim',
          password: 'secret',
        );

        expect(result.isLeft(), isTrue);
        expect(session.hasSession, isFalse);
        expect(repository.cachedUser, isNull);
      },
    );
  });

  group('registration', () {
    test('starts a personal sign up and replaces an older one', () async {
      await setUpWith({SharedPrefKeys.registrationProcessId: 'old-process'});

      final result = await repository.startRegistration();

      expect(result.getOrElse(() => null), RegistrationStep.basicInfo);
      expect(remote.deletedProcesses, ['old-process']);
      expect(repository.pendingProcessId, 'process-1');
      expect(remote.submittedSteps.single.payload, {'accountType': 'personal'});
    });

    test('runs every step through to a signed in user', () async {
      await setUpWith({});
      await repository.startRegistration();

      final afterBasics = await repository.submitBasicInfo(
        const BasicInfo(
          firstName: 'Slim',
          lastName: 'Shady',
          email: 'slim@example.com',
          username: 'slim',
        ),
      );
      expect(afterBasics.getOrElse(() => null), RegistrationStep.passwordSetup);

      await repository.submitPassword('Secret123');
      expect(session.accessToken, 'new-access');

      final afterProfile = await repository.submitAgeGender(
        dateOfBirth: DateTime(1995, 5, 17),
        gender: Gender.female,
      );
      expect(afterProfile.getOrElse(() => null), RegistrationStep.currents);
      expect(
        remote.submittedSteps.map((s) => s.step),
        containsAllInOrder([
          RegistrationStep.ageGender,
          RegistrationStep.themeSelection,
          RegistrationStep.creatorMode,
        ]),
      );
      expect(
        remote.submittedSteps
            .firstWhere((s) => s.step == RegistrationStep.ageGender)
            .payload,
        {'dateOfBirth': '1995-05-17T00:00:00.000Z', 'gender': 'female'},
      );

      final finished = await repository.completeRegistration(['c1']);
      expect(finished.isRight(), isTrue);
      expect(remote.completedProcesses, ['process-1']);
      expect(repository.pendingProcessId, isNull);
      expect(repository.cachedUser?.id, 'user-1');
    });

    test('asks the user to start again when the sign up is gone', () async {
      await setUpWith({});

      final result = await repository.submitPassword('Secret123');

      expect(
        result.fold((failure) => failure.message, (_) => null),
        'Your sign up session has ended. Please start again.',
      );
    });

    test('forgets an expired sign up when resuming', () async {
      await setUpWith({SharedPrefKeys.registrationProcessId: 'process-1'});
      remote.processStatus = 'expired';

      final result = await repository.resumeRegistration();

      expect(result.getOrElse(() => RegistrationStep.basicInfo), isNull);
      expect(repository.pendingProcessId, isNull);
    });
  });
}
