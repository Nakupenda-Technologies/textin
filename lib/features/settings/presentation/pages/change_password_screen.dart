import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../../auth/presentation/widgets/password_strength_bar.dart';
import '../../../auth/presentation/widgets/password_visibility_button.dart';
import '../../../auth/validators.dart';
import '../../repository/settings_repository.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true;
  bool _isSaving = false;
  String? _currentError;
  String? _newError;
  String? _confirmationError;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _currentError = AuthValidators.loginPassword(_current.text);
      _newError = AuthValidators.newPassword(_new.text);
      _confirmationError = AuthValidators.confirmPassword(
        _confirmation.text,
        _new.text,
      );
    });
    if (_currentError != null ||
        _newError != null ||
        _confirmationError != null) {
      return;
    }

    setState(() => _isSaving = true);
    final result = await locator<SettingsRepository>().changePassword(
      _current.text,
      _new.text,
    );
    if (!mounted) return;
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      setState(() {
        _isSaving = false;
        _currentError = failure.message;
      });
      return;
    }

    await signOutToLogin(
      ref,
      message: 'Password changed. Sign in with your new password.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibility = PasswordVisibilityButton(
      isHidden: _hidden,
      onPressed: () => setState(() => _hidden = !_hidden),
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              "You'll be signed out on every device after changing it.",
              style: AppTextStyle.bodySecondary,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Current password',
              hintText: 'Your current password',
              controller: _current,
              obscureText: _hidden,
              errorText: _currentError,
              autofillHints: const [AutofillHints.password],
              suffixIcon: visibility,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'New password',
              hintText: 'At least 8 characters',
              controller: _new,
              obscureText: _hidden,
              errorText: _newError,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: visibility,
              onChanged: (_) => setState(() => _newError = null),
            ),
            if (_new.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              PasswordStrengthBar(password: _new.text),
            ],
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirm new password',
              hintText: 'Type it again',
              controller: _confirmation,
              obscureText: _hidden,
              errorText: _confirmationError,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              suffixIcon: visibility,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Change password',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
