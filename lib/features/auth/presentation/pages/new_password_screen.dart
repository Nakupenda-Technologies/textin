import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../notifier/password_reset_notifier.dart';
import '../../validators.dart';
import '../widgets/auth_form_scaffold.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/password_visibility_button.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
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
        .read(passwordResetNotifierProvider.notifier)
        .resetPassword(
          password: _password.text,
          confirmation: _confirmation.text,
        );
    if (!mounted) return;
    switch (outcome) {
      case PasswordResetOutcome.done:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
      case PasswordResetOutcome.codeRejected:
        Navigator.of(context).pop();
      case PasswordResetOutcome.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetNotifierProvider);
    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    final enabled = !state.isSubmitting;

    return AuthFormScaffold(
      canGoBack: true,
      title: 'New Password',
      subtitle: 'Enter a strong password and store it securely.',
      action: ListenableBuilder(
        listenable: _fields,
        builder: (context, _) => AppButton(
          label: 'Change Password',
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
          errorText: state.errorFor(PasswordResetField.password),
          helperText: state.errorFor(PasswordResetField.password) == null
              ? 'At least ${AuthValidators.minimumPasswordLength} characters with a letter and a number.'
              : null,
          suffixIcon: PasswordVisibilityButton(
            isHidden: _isPasswordHidden,
            onPressed: () =>
                setState(() => _isPasswordHidden = !_isPasswordHidden),
          ),
          onChanged: (_) {
            notifier.clearError(PasswordResetField.password);
            notifier.clearError(PasswordResetField.confirmPassword);
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
          errorText: state.errorFor(PasswordResetField.confirmPassword),
          suffixIcon: PasswordVisibilityButton(
            isHidden: _isConfirmationHidden,
            onPressed: () =>
                setState(() => _isConfirmationHidden = !_isConfirmationHidden),
          ),
          onChanged: (_) =>
              notifier.clearError(PasswordResetField.confirmPassword),
          onSubmitted: (_) {
            if (_isComplete) _submit();
          },
        ),
      ],
    );
  }
}
