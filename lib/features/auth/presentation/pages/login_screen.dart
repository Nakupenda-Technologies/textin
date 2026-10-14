import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../notifier/login_notifier.dart';
import '../../notifier/registration_notifier.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/password_visibility_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TapGestureRecognizer _createAccountTap = TapGestureRecognizer()
    ..onTap = _openSignUp;
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _createAccountTap.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _identifierController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final signedIn = await ref
        .read(loginNotifierProvider.notifier)
        .signIn(
          identifier: _identifierController.text,
          password: _passwordController.text,
        );
    if (!signedIn || !mounted) return;

    TextInput.finishAutofillContext();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.inbox, (_) => false);
  }

  void _openSignUp() {
    ref.read(registrationNotifierProvider.notifier).beginNewSignUp();
    Navigator.of(context).pushNamed(AppRouter.createAccount);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginNotifierProvider);
    final notifier = ref.read(loginNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthBrandHeader(),
              const SizedBox(height: 40),
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
              Text(
                'Exhale',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 32),
              AutofillGroup(
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Email or Username',
                      hintText: 'i.e. slim | slim@gmail.com',
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      errorText: state.identifierError,
                      enabled: !state.isSubmitting,
                      onChanged: (_) => notifier.clearIdentifierError(),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      controller: _passwordController,
                      obscureText: _isPasswordHidden,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      errorText: state.passwordError,
                      enabled: !state.isSubmitting,
                      onChanged: (_) => notifier.clearPasswordError(),
                      onSubmitted: (_) => _signIn(),
                      suffixIcon: PasswordVisibilityButton(
                        isHidden: _isPasswordHidden,
                        onPressed: () => setState(
                          () => _isPasswordHidden = !_isPasswordHidden,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _identifierController,
                  _passwordController,
                ]),
                builder: (context, _) => AppButton(
                  label: 'Login',
                  isLoading: state.isSubmitting,
                  onPressed: _canSubmit ? _signIn : null,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don't have an account yet? ",
                    style: TextStyle(
                      fontFamily: AppTheme.accentFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(
                          color: AppTheme.textred,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: _createAccountTap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
