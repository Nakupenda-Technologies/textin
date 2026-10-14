import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../notifier/password_reset_notifier.dart';
import '../widgets/auth_form_scaffold.dart';
import '../widgets/code_input.dart';

class ResetCodeScreen extends ConsumerStatefulWidget {
  const ResetCodeScreen({super.key});

  @override
  ConsumerState<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends ConsumerState<ResetCodeScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final accepted = ref
        .read(passwordResetNotifierProvider.notifier)
        .acceptCode(_code.text);
    if (!accepted) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushNamed(AppRouter.newPassword);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetNotifierProvider);
    final notifier = ref.read(passwordResetNotifierProvider.notifier);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final email = state.email ?? 'your email';
    final seconds = state.resendSeconds;

    return AuthFormScaffold(
      canGoBack: true,
      title: 'Enter Code',
      subtitle:
          'We sent a ${PasswordResetNotifier.codeLength}-digit code to $email.',
      action: ListenableBuilder(
        listenable: _code,
        builder: (context, _) => AppButton(
          label: 'Submit',
          onPressed: _code.text.length == PasswordResetNotifier.codeLength
              ? _submit
              : null,
        ),
      ),
      children: [
        CodeInput(
          controller: _code,
          length: PasswordResetNotifier.codeLength,
          errorText: state.errorFor(PasswordResetField.code),
          onChanged: (_) => notifier.clearError(PasswordResetField.code),
          onCompleted: (_) => _submit(),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Didn't get it?",
              style: TextStyle(
                fontSize: 14,
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
            TextButton(
              onPressed: state.canResend ? notifier.resendCode : null,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textred,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(
                seconds > 0
                    ? 'Resend in 0:${seconds.toString().padLeft(2, '0')}'
                    : 'Resend code',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
