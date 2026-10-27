import 'package:flutter_riverpod/legacy.dart';

import '../../../core/errors/error_message.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/auth_user.dart';
import '../repository/auth_repository.dart';
import '../validators.dart';
import 'session_notifier.dart';

class LoginState {
  const LoginState({
    this.isSubmitting = false,
    this.identifierError,
    this.passwordError,
  });

  final bool isSubmitting;
  final String? identifierError;
  final String? passwordError;
}

final loginNotifierProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, LoginState>((ref) {
      return LoginNotifier(
        repository: ref.watch(authRepositoryProvider),
        onSignedIn: (user) =>
            ref.read(currentUserProvider.notifier).state = user,
      );
    });

class LoginNotifier extends StateNotifier<LoginState> {
  LoginNotifier({
    required AuthRepository repository,
    required this.onSignedIn,
    Toaster toaster = const Toaster(),
  }) : _repository = repository,
       _toaster = toaster,
       super(const LoginState());

  final AuthRepository _repository;
  final Toaster _toaster;
  final void Function(AuthUser user) onSignedIn;

  void clearIdentifierError() {
    if (state.identifierError == null) return;
    state = LoginState(
      isSubmitting: state.isSubmitting,
      passwordError: state.passwordError,
    );
  }

  void clearPasswordError() {
    if (state.passwordError == null) return;
    state = LoginState(
      isSubmitting: state.isSubmitting,
      identifierError: state.identifierError,
    );
  }

  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    if (state.isSubmitting) return false;

    final identifierError = AuthValidators.identifier(identifier);
    final passwordError = AuthValidators.loginPassword(password);
    if (identifierError != null || passwordError != null) {
      state = LoginState(
        identifierError: identifierError,
        passwordError: passwordError,
      );
      return false;
    }

    state = const LoginState(isSubmitting: true);
    final result = await _repository.signIn(
      identifier: identifier.trim(),
      password: password,
    );
    if (!mounted) return false;
    state = const LoginState();

    return result.fold(
      (failure) {
        _toaster.error("Couldn't sign you in", userMessage(failure));
        return false;
      },
      (user) {
        onSignedIn(user);
        return true;
      },
    );
  }
}
