import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../../auth/presentation/widgets/code_input.dart';
import '../../../auth/validators.dart';
import '../../repository/settings_repository.dart';

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  static const codeLength = 6;

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  String? _error;
  bool _isBusy = false;

  SettingsRepository get _repository => locator<SettingsRepository>();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    final invalid = AuthValidators.email(email);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });
    final result = await _repository.requestEmailChange(email);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      result.fold((f) => _error = f.message, (_) => _sentTo = email);
    });
  }

  Future<void> _confirm() async {
    final email = _sentTo!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _isBusy = true;
      _error = null;
    });

    final result = await _repository.confirmEmailChange(email, _code.text);
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _error = failure.message;
        });
      }
      return;
    }

    final refreshed = await ref.read(authRepositoryProvider).refreshUser();
    refreshed.fold(
      (_) {},
      (user) => ref.read(currentUserProvider.notifier).state = user,
    );
    messenger.showSnackBar(const SnackBar(content: Text('Email updated')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sentTo = _sentTo;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      appBar: AppBar(title: const Text('Change email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: sentTo == null
              ? [
                  Text(
                    "We'll send a code to your new address to confirm it.",
                    style: AppTextStyle.bodySecondary,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'New email',
                    hintText: 'you@example.com',
                    controller: _email,
                    errorText: _error,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _sendCode(),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Send code',
                    isLoading: _isBusy,
                    onPressed: _sendCode,
                  ),
                ]
              : [
                  Text(
                    'Enter the ${ChangeEmailScreen.codeLength}-digit code we '
                    'sent to $sentTo.',
                    style: AppTextStyle.bodySecondary,
                  ),
                  const SizedBox(height: 20),
                  CodeInput(
                    controller: _code,
                    length: ChangeEmailScreen.codeLength,
                    errorText: _error,
                    enabled: !_isBusy,
                    onChanged: (_) => setState(() => _error = null),
                    onCompleted: (_) => _confirm(),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Confirm',
                    isLoading: _isBusy,
                    onPressed: _code.text.length == ChangeEmailScreen.codeLength
                        ? _confirm
                        : null,
                  ),
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => setState(() {
                            _sentTo = null;
                            _code.clear();
                            _error = null;
                          }),
                    child: const Text('Use a different email'),
                  ),
                ],
        ),
      ),
    );
  }
}
