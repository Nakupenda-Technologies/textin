import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/errors/failure.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../repository/settings_repository.dart';
import '../widgets/account_dialogs.dart';
import '../widgets/settings_page.dart';
import '../widgets/settings_tiles.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  void _open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _deactivate() async {
    if (!await confirmDeactivation(context)) return;
    final result = await locator<SettingsRepository>().deactivateAccount();
    result.fold(
      _showFailure,
      (_) => signOutToLogin(
        ref,
        message: 'Account deactivated. Sign in again to reactivate it.',
      ),
    );
  }

  Future<void> _delete() async {
    final password = await askPasswordToDelete(context);
    if (password == null) return;
    final result = await locator<SettingsRepository>().deleteAccount(password);
    result.fold(
      _showFailure,
      (_) => signOutToLogin(ref, message: 'Your account has been deleted.'),
    );
  }

  void _showFailure(Failure failure) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider)?.email;

    return SettingsPage(
      title: 'Account',
      children: [
        SettingsRow(
          title: 'Email',
          subtitle: email,
          trailing: SettingsPillButton(
            label: 'Edit',
            onPressed: () => _open(const ChangeEmailScreen()),
          ),
        ),
        SettingsRow(
          title: 'Password',
          subtitle: List.filled(14, '*').join(' '),
          trailing: SettingsPillButton(
            label: 'Change',
            onPressed: () => _open(const ChangePasswordScreen()),
          ),
        ),
        SettingsRow(
          title: 'Deactivate my account',
          subtitle: 'Hide your profile and content temporarily.',
          trailing: SettingsPillButton(
            label: 'Deactivate',
            onPressed: _deactivate,
          ),
        ),
        SettingsRow(
          title: 'Delete my account',
          subtitle:
              'Permanently delete your data and profile. '
              'This cannot be undone.',
          trailing: SettingsPillButton(
            label: 'Delete',
            destructive: true,
            onPressed: _delete,
          ),
        ),
      ],
    );
  }
}
