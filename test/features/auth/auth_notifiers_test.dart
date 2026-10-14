import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/storage/session_store.dart';
import 'package:textin/features/auth/models/auth_user.dart';
import 'package:textin/features/auth/models/current_item.dart';
import 'package:textin/features/auth/models/registration_details.dart';
import 'package:textin/features/auth/models/registration_step.dart';
import 'package:textin/features/auth/notifier/login_notifier.dart';
import 'package:textin/features/auth/notifier/registration_notifier.dart';
import 'package:textin/features/auth/repository/auth_repository.dart';
import 'package:textin/services/local_storage_service.dart';

import '../../helpers/recording_toaster.dart';
import 'fake_auth_remote_data_source.dart';

void main() {
  late FakeAuthRemoteDataSource remote;
  late AuthRepository repository;
  late List<AuthUser> signedIn;
  late RecordingToaster toaster;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorageService.init();
    remote = FakeAuthRemoteDataSource();
    final session = SessionStore();
    await session.load();
    repository = AuthRepository(remote: remote, session: session);
    signedIn = [];
    toaster = RecordingToaster();
  });

  group('LoginNotifier', () {
    late LoginNotifier notifier;

    setUp(() {
      notifier = LoginNotifier(
        repository: repository,
        onSignedIn: signedIn.add,
        toaster: toaster,
      );
    });

    test('shows field errors without calling the server', () async {
      final ok = await notifier.signIn(identifier: ' ', password: '');

      expect(ok, isFalse);
      expect(notifier.state.identifierError, 'Enter your email or username.');
      expect(notifier.state.passwordError, 'Enter your password.');
      expect(signedIn, isEmpty);
    });

    test('signs in and reports the user', () async {
      final ok = await notifier.signIn(identifier: 'slim ', password: 'pw');

      expect(ok, isTrue);
      expect(signedIn.single, FakeAuthRemoteDataSource.user);
      expect(notifier.state.isSubmitting, isFalse);
    });

    test('stays on the form when the server rejects the password', () async {
      remote.loginFailure = const ServerFailure(
        'Invalid credentials',
        statusCode: 401,
      );

      final ok = await notifier.signIn(identifier: 'slim', password: 'pw');

      expect(ok, isFalse);
      expect(notifier.state.isSubmitting, isFalse);
      expect(signedIn, isEmpty);
      expect(toaster.errors.single, (
        title: "Couldn't sign you in",
        message: 'Invalid credentials.',
      ));
    });

    test('explains a lost connection in plain language', () async {
      remote.loginFailure = const NetworkFailure();

      await notifier.signIn(identifier: 'slim', password: 'pw');

      expect(
        toaster.errors.single.message,
        "You're offline. Check your connection and try again.",
      );
    });
  });

  group('RegistrationNotifier', () {
    late RegistrationNotifier notifier;

    setUp(() {
      notifier = RegistrationNotifier(
        repository: repository,
        onSignedIn: signedIn.add,
        usernameDebounce: Duration.zero,
        toaster: toaster,
      );
    });

    tearDown(() => notifier.dispose());

    Future<RegistrationOutcome> submitValidBasics() => notifier.submitBasicInfo(
      firstName: 'Slim',
      lastName: 'Shady',
      email: 'slim@example.com',
      username: 'slim',
      referralCode: '  ',
    );

    test('a new sign up starts a fresh process on the first step', () async {
      SharedPreferences.setMockInitialValues({});
      notifier.beginNewSignUp();

      final outcome = await submitValidBasics();

      expect(outcome, isA<RegistrationContinues>());
      expect(
        (outcome as RegistrationContinues).nextStep,
        RegistrationStep.passwordSetup,
      );
      expect(remote.submittedSteps.map((s) => s.step), [
        RegistrationStep.accountType,
        RegistrationStep.basicInfo,
      ]);
    });

    test('validates every basic info field at once', () async {
      final outcome = await notifier.submitBasicInfo(
        firstName: '',
        lastName: '',
        email: 'nope',
        username: 'a',
        referralCode: '',
      );

      expect(outcome, isA<RegistrationFailed>());
      expect(notifier.state.errors.keys, {
        RegistrationField.firstName,
        RegistrationField.lastName,
        RegistrationField.email,
        RegistrationField.username,
      });
    });

    test('flags a taken username after the availability check', () async {
      remote.usernameAvailable = false;

      notifier.onUsernameChanged('slim');
      expect(notifier.state.usernameStatus, UsernameStatus.checking);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.usernameStatus, UsernameStatus.taken);
      expect(
        notifier.state.errorFor(RegistrationField.username),
        'That username is taken. Try another one.',
      );
    });

    test('puts server conflicts under the matching field', () async {
      notifier.beginNewSignUp();
      remote.failingStep = RegistrationStep.basicInfo;
      remote.stepFailure = const ServerFailure(
        'Email already in use',
        statusCode: 409,
      );

      final outcome = await submitValidBasics();

      expect(outcome, isA<RegistrationFailed>());
      expect(
        notifier.state.errorFor(RegistrationField.email),
        'Email already in use.',
      );
      expect(toaster.errors, isEmpty);
    });

    test('shows other server failures as a toast', () async {
      notifier.beginNewSignUp();
      remote.failingStep = RegistrationStep.basicInfo;
      remote.stepFailure = const ServerFailure('', statusCode: 503);

      await submitValidBasics();

      expect(toaster.errors.single, (
        title: "Couldn't save your details",
        message: 'Something went wrong on our side. Please try again.',
      ));
    });

    test('sends a trimmed payload without an empty referral code', () async {
      notifier.beginNewSignUp();

      final outcome = await submitValidBasics();

      expect(outcome, isA<RegistrationContinues>());
      expect(remote.submittedSteps.last.payload, {
        'firstName': 'Slim',
        'lastName': 'Shady',
        'email': 'slim@example.com',
        'username': 'slim',
      });
    });

    test('rejects mismatched passwords before calling the server', () async {
      final outcome = await notifier.submitPassword(
        password: 'longpass1',
        confirmation: 'longpass2',
      );

      expect(outcome, isA<RegistrationFailed>());
      expect(
        notifier.state.errorFor(RegistrationField.confirmPassword),
        'The passwords do not match.',
      );
    });

    test('requires age and gender', () async {
      final outcome = await notifier.submitAgeGender(
        dateOfBirth: DateTime.now(),
        gender: null,
      );

      expect(outcome, isA<RegistrationFailed>());
      expect(notifier.state.errors.keys, {
        RegistrationField.dateOfBirth,
        RegistrationField.gender,
      });
    });

    test('limits currents and completes sign up', () async {
      remote.currents = [
        for (var i = 0; i < 7; i++) CurrentItem(id: 'c$i', name: 'Current $i'),
      ];
      notifier.beginNewSignUp();
      await submitValidBasics();
      await notifier.loadCurrents();

      final empty = await notifier.completeRegistration();
      expect(empty, isA<RegistrationFailed>());
      expect(
        notifier.state.errorFor(RegistrationField.currents),
        'Choose at least 1 current.',
      );

      for (final current in notifier.state.currents) {
        notifier.toggleCurrent(current);
      }
      expect(
        notifier.state.selectedCurrentIds.length,
        RegistrationNotifier.maxCurrents,
      );
      expect(notifier.state.errorFor(RegistrationField.currents), isNull);
      expect(toaster.infos, [
        'You can choose up to 5 currents.',
        'You can choose up to 5 currents.',
      ]);

      final outcome = await notifier.completeRegistration();
      expect(outcome, isA<RegistrationCompleted>());
      expect(signedIn.single.id, 'user-1');
    });

    test('keeps gender values the server expects', () {
      expect(Gender.values.map((g) => g.apiValue), ['male', 'female', 'other']);
    });
  });
}
