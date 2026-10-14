import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../notifier/registration_notifier.dart';
import '../../validators.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/password_visibility_button.dart';
import '../widgets/auth_form_scaffold.dart';

class CreatePasswordScreen extends ConsumerStatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  ConsumerState<CreatePasswordScreen> createState() =>
      _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late final Listenable _fields = Listenable.merge([_password, _confirmation]);
  bool _isPasswordHidden = true;
  bool _isConfirmationHidden = true;

  bool get _isComplete =>
      _password.text.isNotEmpty && _confirmation.text.isNotEmpty;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final outcome = await ref
        .read(registrationNotifierProvider.notifier)
        .submitPassword(
          password: _password.text,
          confirmation: _confirmation.text,
        );
    if (!mounted || outcome is! RegistrationContinues) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.routeForRegistrationStep(outcome.nextStep),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationNotifierProvider);
    final notifier = ref.read(registrationNotifierProvider.notifier);
    final enabled = !state.isSubmitting;

    return AuthFormScaffold(
      step: 2,
      canGoBack: true,
      title: 'Secure Your Account',
      subtitle: 'Create a strong password and store it securely.',
      action: ListenableBuilder(
        listenable: _fields,
        builder: (context, _) => AppButton(
          label: 'Next Step',
          isLoading: state.isSubmitting,
          onPressed: _isComplete ? _submit : null,
        ),
      ),
      children: [
        AppTextField(
          label: 'Enter New Password',
          hintText: 'Create a password',
          controller: _password,
          enabled: enabled,
          obscureText: _isPasswordHidden,
          autofillHints: const [AutofillHints.newPassword],
          errorText: state.errorFor(RegistrationField.password),
          helperText: state.errorFor(RegistrationField.password) == null
              ? 'At least ${AuthValidators.minimumPasswordLength} characters with a letter and a number.'
              : null,
          suffixIcon: PasswordVisibilityButton(
            isHidden: _isPasswordHidden,
            onPressed: () =>
                setState(() => _isPasswordHidden = !_isPasswordHidden),
          ),
          onChanged: (_) {
            notifier.clearError(RegistrationField.password);
            notifier.clearError(RegistrationField.confirmPassword);
          },
        ),
        ListenableBuilder(
          listenable: _password,
          builder: (context, _) =>
              PasswordStrengthBar(password: _password.text),
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Confirm Password',
          hintText: 'Re-enter your password',
          controller: _confirmation,
          enabled: enabled,
          obscureText: _isConfirmationHidden,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: state.errorFor(RegistrationField.confirmPassword),
          suffixIcon: PasswordVisibilityButton(
            isHidden: _isConfirmationHidden,
            onPressed: () =>
                setState(() => _isConfirmationHidden = !_isConfirmationHidden),
          ),
          onChanged: (_) =>
              notifier.clearError(RegistrationField.confirmPassword),
          onSubmitted: (_) {
            if (_isComplete) _submit();
          },
        ),
      ],
    );
  }
}
