import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_message.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/auth_user.dart';
import '../models/current_item.dart';
import '../models/registration_details.dart';
import '../models/registration_step.dart';
import '../repository/auth_repository.dart';
import '../validators.dart';
import 'session_notifier.dart';

enum RegistrationField {
  firstName,
  lastName,
  email,
  username,
  referralCode,
  password,
  confirmPassword,
  dateOfBirth,
  gender,
  currents,
}

enum UsernameStatus { idle, checking, available, taken }

sealed class RegistrationOutcome {
  const RegistrationOutcome();
}

class RegistrationFailed extends RegistrationOutcome {
  const RegistrationFailed();
}

class RegistrationContinues extends RegistrationOutcome {
  const RegistrationContinues(this.nextStep);

  final RegistrationStep? nextStep;
}

class RegistrationCompleted extends RegistrationOutcome {
  const RegistrationCompleted(this.user);

  final AuthUser user;
}

class RegistrationState {
  const RegistrationState({
    this.isSubmitting = false,
    this.errors = const {},
    this.usernameStatus = UsernameStatus.idle,
    this.currents = const [],
    this.isLoadingCurrents = false,
    this.currentsLoadFailed = false,
    this.selectedCurrentIds = const {},
  });

  final bool isSubmitting;
  final Map<RegistrationField, String> errors;
  final UsernameStatus usernameStatus;
  final List<CurrentItem> currents;
  final bool isLoadingCurrents;
  final bool currentsLoadFailed;
  final Set<String> selectedCurrentIds;

  String? errorFor(RegistrationField field) => errors[field];

  RegistrationState copyWith({
    bool? isSubmitting,
    Map<RegistrationField, String>? errors,
    UsernameStatus? usernameStatus,
    List<CurrentItem>? currents,
    bool? isLoadingCurrents,
    bool? currentsLoadFailed,
    Set<String>? selectedCurrentIds,
  }) => RegistrationState(
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errors: errors ?? this.errors,
    usernameStatus: usernameStatus ?? this.usernameStatus,
    currents: currents ?? this.currents,
    isLoadingCurrents: isLoadingCurrents ?? this.isLoadingCurrents,
    currentsLoadFailed: currentsLoadFailed ?? this.currentsLoadFailed,
    selectedCurrentIds: selectedCurrentIds ?? this.selectedCurrentIds,
  );
}

final registrationNotifierProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
      return RegistrationNotifier(
        repository: ref.watch(authRepositoryProvider),
        onSignedIn: (user) =>
            ref.read(currentUserProvider.notifier).state = user,
      );
    });

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier({
    required AuthRepository repository,
    required this.onSignedIn,
    this.usernameDebounce = const Duration(milliseconds: 600),
    Toaster toaster = const Toaster(),
  }) : _repository = repository,
       _toaster = toaster,
       super(const RegistrationState());

  static const int minCurrents = 1;
  static const int maxCurrents = 5;

  final AuthRepository _repository;
  final Toaster _toaster;
  final void Function(AuthUser user) onSignedIn;
  final Duration usernameDebounce;

  Timer? _usernameTimer;
  String? _latestUsername;
  bool _needsNewProcess = false;

  @override
  void dispose() {
    _usernameTimer?.cancel();
    super.dispose();
  }

  void clearError(RegistrationField field) {
    if (!state.errors.containsKey(field)) return;
    state = state.copyWith(errors: Map.of(state.errors)..remove(field));
  }

  void beginNewSignUp() {
    _usernameTimer?.cancel();
    _latestUsername = null;
    _needsNewProcess = true;
    state = const RegistrationState();
  }

  void onUsernameChanged(String value) {
    _usernameTimer?.cancel();
    final username = value.trim();
    _latestUsername = username;
    clearError(RegistrationField.username);

    if (AuthValidators.username(username) != null) {
      state = state.copyWith(usernameStatus: UsernameStatus.idle);
      return;
    }

    state = state.copyWith(usernameStatus: UsernameStatus.checking);
    _usernameTimer = Timer(usernameDebounce, () async {
      final result = await _repository.isUsernameAvailable(username);
      if (!mounted || _latestUsername != username) return;

      result.fold(
        (_) => state = state.copyWith(usernameStatus: UsernameStatus.idle),
        (available) => state = state.copyWith(
          usernameStatus: available
              ? UsernameStatus.available
              : UsernameStatus.taken,
          errors: available
              ? null
              : {
                  ...state.errors,
                  RegistrationField.username: _usernameTakenMessage,
                },
        ),
      );
    });
  }

  Future<RegistrationOutcome> submitBasicInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String referralCode,
  }) async {
    final errors = <RegistrationField, String>{
      RegistrationField.firstName: ?AuthValidators.name(
        firstName,
        field: 'first name',
      ),
      RegistrationField.lastName: ?AuthValidators.name(
        lastName,
        field: 'last name',
      ),
      RegistrationField.email: ?AuthValidators.email(email),
      RegistrationField.username:
          ?(AuthValidators.username(username) ??
          (state.usernameStatus == UsernameStatus.taken
              ? _usernameTakenMessage
              : null)),
    };
    if (!_beginSubmit(errors)) return const RegistrationFailed();

    if (_needsNewProcess || _repository.pendingProcessId == null) {
      final started = await _repository.startRegistration();
      if (started.isLeft()) {
        return _finishStep(started, failureTitle: "Couldn't start sign up");
      }
      _needsNewProcess = false;
    }

    final referral = referralCode.trim();
    return _finishStep(
      await _repository.submitBasicInfo(
        BasicInfo(
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: email.trim(),
          username: username.trim(),
          referralCode: referral.isEmpty ? null : referral,
        ),
      ),
      failureTitle: "Couldn't save your details",
      fields: const {
        RegistrationField.firstName,
        RegistrationField.lastName,
        RegistrationField.email,
        RegistrationField.username,
        RegistrationField.referralCode,
      },
    );
  }

  Future<RegistrationOutcome> submitPassword({
    required String password,
    required String confirmation,
  }) async {
    final errors = <RegistrationField, String>{
      RegistrationField.password: ?AuthValidators.newPassword(password),
      RegistrationField.confirmPassword: ?AuthValidators.confirmPassword(
        confirmation,
        password,
      ),
    };
    if (!_beginSubmit(errors)) return const RegistrationFailed();

    return _finishStep(
      await _repository.submitPassword(password),
      failureTitle: "Couldn't secure your account",
      fields: const {RegistrationField.password},
    );
  }

  Future<RegistrationOutcome> submitAgeGender({
    required DateTime? dateOfBirth,
    required Gender? gender,
  }) async {
    final errors = <RegistrationField, String>{
      RegistrationField.dateOfBirth: ?AuthValidators.dateOfBirth(dateOfBirth),
      if (gender == null) RegistrationField.gender: 'Select your gender.',
    };
    if (!_beginSubmit(errors) || dateOfBirth == null || gender == null) {
      return const RegistrationFailed();
    }

    return _finishStep(
      await _repository.submitAgeGender(
        dateOfBirth: dateOfBirth,
        gender: gender,
      ),
      failureTitle: "Couldn't save your details",
    );
  }

  Future<void> loadCurrents() async {
    if (state.isLoadingCurrents) return;
    state = state.copyWith(isLoadingCurrents: true, currentsLoadFailed: false);

    final result = await _repository.fetchCurrents();
    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoadingCurrents: false,
          currentsLoadFailed: true,
        );
        _toaster.error("Couldn't load currents", userMessage(failure));
      },
      (currents) => state = state.copyWith(
        isLoadingCurrents: false,
        currents: currents,
        selectedCurrentIds: state.selectedCurrentIds
            .where((id) => currents.any((current) => current.id == id))
            .toSet(),
      ),
    );
  }

  void toggleCurrent(CurrentItem current) {
    final selected = Set.of(state.selectedCurrentIds);
    if (!selected.remove(current.id)) {
      if (selected.length >= maxCurrents) {
        _toaster.info('You can choose up to $maxCurrents currents.');
        return;
      }
      selected.add(current.id);
    }
    state = state.copyWith(
      selectedCurrentIds: selected,
      errors: Map.of(state.errors)..remove(RegistrationField.currents),
    );
  }

  Future<RegistrationOutcome> completeRegistration() async {
    final errors = <RegistrationField, String>{
      if (state.selectedCurrentIds.length < minCurrents)
        RegistrationField.currents: 'Choose at least $minCurrents current.',
    };
    if (!_beginSubmit(errors)) return const RegistrationFailed();

    final result = await _repository.completeRegistration(
      state.selectedCurrentIds.toList(),
    );
    if (!mounted) return const RegistrationFailed();
    state = state.copyWith(isSubmitting: false);

    return result.fold(
      (failure) {
        _showFailure("Couldn't finish sign up", failure, const {});
        return const RegistrationFailed();
      },
      (user) {
        onSignedIn(user);
        return RegistrationCompleted(user);
      },
    );
  }

  static const _usernameTakenMessage =
      'That username is taken. Try another one.';

  bool _beginSubmit(Map<RegistrationField, String> errors) {
    if (state.isSubmitting) return false;
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: {...state.errors, ...errors});
      return false;
    }
    state = state.copyWith(isSubmitting: true);
    return true;
  }

  RegistrationOutcome _finishStep(
    Either<Failure, RegistrationStep?> result, {
    required String failureTitle,
    Set<RegistrationField> fields = const {},
  }) {
    if (!mounted) return const RegistrationFailed();
    state = state.copyWith(isSubmitting: false);
    return result.fold((failure) {
      _showFailure(failureTitle, failure, fields);
      return const RegistrationFailed();
    }, RegistrationContinues.new);
  }

  void _showFailure(
    String title,
    Failure failure,
    Set<RegistrationField> visibleFields,
  ) {
    final message = userMessage(failure);
    final field = _fieldForServerMessage(failure);
    if (field == null || !visibleFields.contains(field)) {
      _toaster.error(title, message);
      return;
    }
    state = state.copyWith(errors: {...state.errors, field: message});
  }

  // Validation and conflict errors that clearly belong to one input are shown
  // under that input instead of in a toast.
  RegistrationField? _fieldForServerMessage(Failure failure) {
    final status = failure.statusCode;
    if (status == null || status < 400 || status >= 500) return null;
    final message = failure.message.toLowerCase();
    if (message.contains('referral')) return RegistrationField.referralCode;
    if (message.contains('username')) return RegistrationField.username;
    if (message.contains('email')) return RegistrationField.email;
    if (message.contains('password')) return RegistrationField.password;
    return null;
  }
}
