import 'package:fake_async/fake_async.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textin/core/errors/failure.dart';
import 'package:textin/core/storage/session_store.dart';
import 'package:textin/features/auth/notifier/password_reset_notifier.dart';
import 'package:textin/features/auth/repository/auth_repository.dart';
import 'package:textin/services/local_storage_service.dart';

import '../../helpers/recording_toaster.dart';
import 'fake_auth_remote_data_source.dart';

void main() {
  late FakeAuthRemoteDataSource remote;
  late RecordingToaster toaster;
  late PasswordResetNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await LocalStorageService.init();
    remote = FakeAuthRemoteDataSource();
    final session = SessionStore();
    await session.load();
    toaster = RecordingToaster();
    notifier = PasswordResetNotifier(
      repository: AuthRepository(remote: remote, session: session),
      toaster: toaster,
      resendCooldownSeconds: 3,
    );
  });

  tearDown(() {
    if (notifier.mounted) notifier.dispose();
  });

  test('rejects an invalid email without calling the server', () async {
    final sent = await notifier.requestCode('slim@');

    expect(sent, isFalse);
    expect(
      notifier.state.errorFor(PasswordResetField.email),
      'Enter a valid email address.',
    );
    expect(remote.resetRequests, isEmpty);
  });

  test('sends a code to the trimmed email and starts the countdown', () async {
    final sent = await notifier.requestCode(' slim@example.com ');

    expect(sent, isTrue);
    expect(remote.resetRequests, ['slim@example.com']);
    expect(notifier.state.email, 'slim@example.com');
    expect(notifier.state.resendSeconds, 3);
    expect(notifier.state.canResend, isFalse);
  });

  test('allows a resend once the countdown ends', () {
    fakeAsync((async) {
      notifier.requestCode('slim@example.com');
      async.flushMicrotasks();

      notifier.resendCode();
      async.flushMicrotasks();
      expect(remote.resetRequests.length, 1);

      async.elapse(const Duration(seconds: 3));
      expect(notifier.state.canResend, isTrue);

      notifier.resendCode();
      async.flushMicrotasks();
      expect(remote.resetRequests.length, 2);
      expect(toaster.infos.single, 'We sent a new code to slim@example.com.');
    });
  });

  test('only accepts a six digit code', () {
    expect(notifier.acceptCode('12345'), isFalse);
    expect(
      notifier.state.errorFor(PasswordResetField.code),
      'Enter the 6-digit code from your email.',
    );
    expect(notifier.acceptCode('123456'), isTrue);
    expect(notifier.state.errorFor(PasswordResetField.code), isNull);
  });

  test('changes the password with the email and code', () async {
    await notifier.requestCode('slim@example.com');
    notifier.acceptCode('123456');

    final outcome = await notifier.resetPassword(
      password: 'newpass12',
      confirmation: 'newpass12',
    );

    expect(outcome, PasswordResetOutcome.done);
    expect(remote.lastReset, (
      email: 'slim@example.com',
      code: '123456',
      newPassword: 'newpass12',
    ));
    expect(
      toaster.infos.last,
      'Your password has been changed. Sign in with your new password.',
    );
  });

  test('sends the user back to the code when the server rejects it', () async {
    await notifier.requestCode('slim@example.com');
    notifier.acceptCode('123456');
    remote.resetFailure = const ServerFailure(
      'Invalid or expired code',
      statusCode: 400,
    );

    final outcome = await notifier.resetPassword(
      password: 'newpass12',
      confirmation: 'newpass12',
    );

    expect(outcome, PasswordResetOutcome.codeRejected);
    expect(
      notifier.state.errorFor(PasswordResetField.code),
      'Invalid or expired code.',
    );
    expect(toaster.errors, isEmpty);
  });

  test('explains other failures in plain language', () async {
    await notifier.requestCode('slim@example.com');
    notifier.acceptCode('123456');
    remote.resetFailure = const NetworkFailure();

    final outcome = await notifier.resetPassword(
      password: 'newpass12',
      confirmation: 'newpass12',
    );

    expect(outcome, PasswordResetOutcome.failed);
    expect(toaster.errors.single, (
      title: "Couldn't change your password",
      message: "You're offline. Check your connection and try again.",
    ));
  });

  test('checks the new password before calling the server', () async {
    final outcome = await notifier.resetPassword(
      password: 'short',
      confirmation: 'other',
    );

    expect(outcome, PasswordResetOutcome.failed);
    expect(notifier.state.errors.keys, {
      PasswordResetField.password,
      PasswordResetField.confirmPassword,
    });
    expect(remote.lastReset, isNull);
  });
}
