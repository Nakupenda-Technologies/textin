import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/widgets/app_toast.dart';
import '../repository/auth_repository.dart';
import '../validators.dart';
import 'session_notifier.dart';

enum PasswordResetField { email, code, password, confirmPassword }

enum PasswordResetOutcome { done, failed, codeRejected }

class PasswordResetState {
  const PasswordResetState({
    this.email,
    this.isSubmitting = false,
    this.errors = const {},
    this.resendSeconds = 0,
  });

  final String? email;
  final bool isSubmitting;
  final Map<PasswordResetField, String> errors;
  final int resendSeconds;

  bool get canResend => resendSeconds == 0 && !isSubmitting;

  String? errorFor(PasswordResetField field) => errors[field];

  PasswordResetState copyWith({
    String? email,
    bool? isSubmitting,
    Map<PasswordResetField, String>? errors,
    int? resendSeconds,
  }) => PasswordResetState(
    email: email ?? this.email,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errors: errors ?? this.errors,
    resendSeconds: resendSeconds ?? this.resendSeconds,
  );
}

final passwordResetNotifierProvider =
    StateNotifierProvider<PasswordResetNotifier, PasswordResetState>((ref) {
      return PasswordResetNotifier(
        repository: ref.watch(authRepositoryProvider),
      );
    });

class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  PasswordResetNotifier({
    required AuthRepository repository,
    Toaster toaster = const Toaster(),
    this.resendCooldownSeconds = 45,
  }) : _repository = repository,
       _toaster = toaster,
       super(const PasswordResetState());

  static const int codeLength = 6;

  final AuthRepository _repository;
  final Toaster _toaster;
  final int resendCooldownSeconds;

  Timer? _countdown;
  String? _code;

  static final RegExp _codePattern = RegExp('^\\d{$codeLength}\$');

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void begin() {
    _countdown?.cancel();
    _code = null;
    state = const PasswordResetState();
  }

  void clearError(PasswordResetField field) {
    if (!state.errors.containsKey(field)) return;
    state = state.copyWith(errors: Map.of(state.errors)..remove(field));
  }

  Future<bool> requestCode(String email) async {
    final address = email.trim();
    final error = AuthValidators.email(address);
    if (error != null) {
      state = state.copyWith(
        errors: {...state.errors, PasswordResetField.email: error},
      );
      return false;
    }
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true);
    final result = await _repository.requestPasswordReset(address);
    if (!mounted) return false;
    state = state.copyWith(isSubmitting: false);

    return result.fold(
      (failure) {
        _toaster.error("Couldn't send the code", userMessage(failure));
        return false;
      },
      (_) {
        state = state.copyWith(email: address, errors: const {});
        _startCountdown();
        return true;
      },
    );
  }

  Future<void> resendCode() async {
    final email = state.email;
    if (email == null || !state.canResend) return;

    state = state.copyWith(isSubmitting: true);
    final result = await _repository.requestPasswordReset(email);
    if (!mounted) return;
    state = state.copyWith(isSubmitting: false);

    result.fold(
      (failure) =>
          _toaster.error("Couldn't send a new code", userMessage(failure)),
      (_) {
        _toaster.info('We sent a new code to $email.');
        _startCountdown();
      },
    );
  }

  bool acceptCode(String code) {
    if (!_codePattern.hasMatch(code)) {
      state = state.copyWith(
        errors: {
          ...state.errors,
          PasswordResetField.code:
              'Enter the $codeLength-digit code from your email.',
        },
      );
      return false;
    }
    _code = code;
    clearError(PasswordResetField.code);
    return true;
  }

  Future<PasswordResetOutcome> resetPassword({
    required String password,
    required String confirmation,
  }) async {
    final errors = <PasswordResetField, String>{
      PasswordResetField.password: ?AuthValidators.newPassword(password),
      PasswordResetField.confirmPassword: ?AuthValidators.confirmPassword(
        confirmation,
        password,
      ),
    };
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: {...state.errors, ...errors});
      return PasswordResetOutcome.failed;
    }
    if (state.isSubmitting) return PasswordResetOutcome.failed;

    final email = state.email;
    final code = _code;
    if (email == null || code == null) {
      _toaster.error(
        "Couldn't change your password",
        'Your reset request has ended. Please start again.',
      );
      return PasswordResetOutcome.failed;
    }

    state = state.copyWith(isSubmitting: true);
    final result = await _repository.resetPassword(
      email: email,
      code: code,
      newPassword: password,
    );
    if (!mounted) return PasswordResetOutcome.failed;
    state = state.copyWith(isSubmitting: false);

    return result.fold(
      (failure) {
        final message = userMessage(failure);
        if (_isCodeProblem(failure)) {
          _code = null;
          state = state.copyWith(
            errors: {...state.errors, PasswordResetField.code: message},
          );
          return PasswordResetOutcome.codeRejected;
        }
        _toaster.error("Couldn't change your password", message);
        return PasswordResetOutcome.failed;
      },
      (_) {
        _countdown?.cancel();
        _toaster.info(
          'Your password has been changed. Sign in with your new password.',
        );
        return PasswordResetOutcome.done;
      },
    );
  }

  // The reset endpoint checks the emailed code and the new password in one
  // call, so a wrong or expired code only surfaces here and has to send the
  // user back to the code screen.
  bool _isCodeProblem(Failure failure) {
    final status = failure.statusCode;
    if (status == null || status < 400 || status >= 500) return false;
    final message = failure.message.toLowerCase();
    return const ['code', 'otp', 'expired', 'token'].any(message.contains);
  }

  void _startCountdown() {
    _countdown?.cancel();
    state = state.copyWith(resendSeconds: resendCooldownSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = state.resendSeconds - 1;
      state = state.copyWith(resendSeconds: remaining < 0 ? 0 : remaining);
      if (remaining <= 0) timer.cancel();
    });
  }
}
