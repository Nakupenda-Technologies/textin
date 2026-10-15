import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../notifier/password_reset_notifier.dart';
import '../widgets/auth_form_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final sent = await ref
        .read(passwordResetNotifierProvider.notifier)
        .requestCode(_email.text);
    if (!sent || !mounted) return;
    Navigator.of(context).pushNamed(AppRouter.resetCode);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetNotifierProvider);
    final notifier = ref.read(passwordResetNotifierProvider.notifier);

    return AuthFormScaffold(
      canGoBack: true,
      title: 'Forgot Password?',
      subtitle: "Enter your account email and we'll send you a code.",
      action: ListenableBuilder(
        listenable: _email,
        builder: (context, _) => AppButton(
          label: 'Next Step',
          isLoading: state.isSubmitting,
          onPressed: _email.text.trim().isEmpty ? null : _submit,
        ),
      ),
      children: [
        AppTextField(
          label: 'Enter Your Account Email',
          hintText: 'i.e. slim@gmail.com',
          controller: _email,
          enabled: !state.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          errorText: state.errorFor(PasswordResetField.email),
          onChanged: (_) => notifier.clearError(PasswordResetField.email),
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
