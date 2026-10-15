import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../notifier/registration_notifier.dart';
import '../widgets/auth_form_scaffold.dart';
import '../widgets/username_status_icon.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _referral = TextEditingController();
  late final TapGestureRecognizer _signInTap = TapGestureRecognizer()
    ..onTap = () => Navigator.of(context).maybePop();

  late final Listenable _requiredFields = Listenable.merge([
    _firstName,
    _lastName,
    _email,
    _username,
  ]);

  bool get _isComplete => [
    _firstName,
    _lastName,
    _email,
    _username,
  ].every((controller) => controller.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _username,
      _referral,
    ]) {
      controller.dispose();
    }
    _signInTap.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final outcome = await ref
        .read(registrationNotifierProvider.notifier)
        .submitBasicInfo(
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: _email.text,
          username: _username.text,
          referralCode: _referral.text,
        );
    if (!mounted || outcome is! RegistrationContinues) return;
    Navigator.of(
      context,
    ).pushNamed(AppRouter.routeForRegistrationStep(outcome.nextStep));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationNotifierProvider);
    final notifier = ref.read(registrationNotifierProvider.notifier);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final enabled = !state.isSubmitting;

    return AuthFormScaffold(
      step: 1,
      canGoBack: true,
      title: 'Create Profile',
      subtitle:
          'Connect around your interests, share your thoughts, build meaningful relationships',
      action: ListenableBuilder(
        listenable: _requiredFields,
        builder: (context, _) => AppButton(
          label: 'Register',
          isLoading: state.isSubmitting,
          onPressed: _isComplete ? _submit : null,
        ),
      ),
      footer: Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          style: TextStyle(
            fontFamily: AppTheme.accentFont,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: onSurface.withValues(alpha: 0.7),
          ),
          children: [
            TextSpan(
              text: 'Sign In',
              style: const TextStyle(
                color: AppTheme.textred,
                fontWeight: FontWeight.w600,
              ),
              recognizer: _signInTap,
            ),
          ],
        ),
      ),
      children: [
        AppTextField(
          label: 'First Name',
          hintText: 'i.e. Davon',
          controller: _firstName,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.givenName],
          errorText: state.errorFor(RegistrationField.firstName),
          onChanged: (_) => notifier.clearError(RegistrationField.firstName),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Last Name',
          hintText: 'i.e. Lean',
          controller: _lastName,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.familyName],
          errorText: state.errorFor(RegistrationField.lastName),
          onChanged: (_) => notifier.clearError(RegistrationField.lastName),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Email',
          hintText: 'i.e. slim@gmail.com',
          controller: _email,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          errorText: state.errorFor(RegistrationField.email),
          onChanged: (_) => notifier.clearError(RegistrationField.email),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Username',
          hintText: 'i.e. slimboogie',
          controller: _username,
          enabled: enabled,
          autofillHints: const [AutofillHints.newUsername],
          errorText: state.errorFor(RegistrationField.username),
          helperText: state.usernameStatus == UsernameStatus.available
              ? 'This username is available.'
              : null,
          suffixIcon: state.usernameStatus == UsernameStatus.idle
              ? null
              : UsernameStatusIcon(status: state.usernameStatus),
          onChanged: notifier.onUsernameChanged,
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Referral Code (Optional)',
          hintText: 'i.e. beynd123',
          controller: _referral,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          errorText: state.errorFor(RegistrationField.referralCode),
          onChanged: (_) => notifier.clearError(RegistrationField.referralCode),
          onSubmitted: (_) {
            if (_isComplete) _submit();
          },
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            text: 'By signing up, you agree to the ',
            children: const [
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ', including '),
              TextSpan(
                text: 'Cookie Use',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: '.'),
            ],
          ),
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
