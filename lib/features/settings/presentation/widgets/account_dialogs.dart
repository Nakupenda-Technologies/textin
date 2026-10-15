import 'package:flutter/material.dart';

Future<bool> confirmDeactivation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Deactivate account?'),
      content: const Text(
        'Your profile and messages will be hidden until you sign in again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Deactivate'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<String?> askPasswordToDelete(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _DeleteAccountDialog(),
);

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your profile and messages. '
            "It can't be undone.",
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              helperText: 'Leave empty if you signed up with Google or Apple.',
              helperMaxLines: 2,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: error),
          onPressed: () => Navigator.of(context).pop(_password.text),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
