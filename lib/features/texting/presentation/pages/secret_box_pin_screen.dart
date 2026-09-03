import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_style.dart';
import '../../cubit/inbox/inbox_cubit.dart';
import '../../cubit/secret_box/secret_box_cubit.dart';
import '../../cubit/secret_box/secret_box_state.dart';
import '../../repository/texting_repository.dart';
import 'secret_box_screen.dart';

class SecretBoxPinScreen extends StatelessWidget {
  const SecretBoxPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUserId = context.read<InboxCubit>().myUserId;
    return BlocProvider(
      create: (_) => SecretBoxCubit(
        repository: locator<TextingRepository>(),
        myUserId: myUserId,
      ),
      child: const _PinView(),
    );
  }
}

class _PinView extends StatefulWidget {
  const _PinView();

  @override
  State<_PinView> createState() => _PinViewState();
}

class _PinViewState extends State<_PinView> {
  String _enteredPin = '';

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += digit);
      if (_enteredPin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  Future<void> _submitPin() async {
    final cubit = context.read<SecretBoxCubit>();
    if (!cubit.state.hasPin) {
      // Set new PIN
      await cubit.setPin(_enteredPin);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SecretBoxScreen()),
        );
      }
    } else {
      // Verify existing PIN
      final ok = await cubit.verifyPin(_enteredPin);
      if (ok && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SecretBoxScreen()),
        );
      } else {
        setState(() => _enteredPin = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<SecretBoxCubit, SecretBoxState>(
          builder: (context, state) {
            final isSetup = !state.hasPin;
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSetup ? 'Create Secret PIN' : 'Enter Secret PIN',
                      style: AppTextStyle.heading1.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSetup
                          ? 'Set a 4-digit PIN to secure your private chats'
                          : 'Enter your 4-digit PIN to access hidden chats',
                      style: AppTextStyle.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _buildPinDots(),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                _buildKeypad(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < _enteredPin.length;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : AppColors.border,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'delete'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 72, height: 72);
                }
                if (key == 'delete') {
                  return SizedBox(
                    width: 72,
                    height: 72,
                    child: IconButton(
                      icon: const Icon(Icons.backspace_outlined, size: 24),
                      onPressed: _onBackspace,
                    ),
                  );
                }
                return InkWell(
                  onTap: () => _onKeyPress(key),
                  borderRadius: BorderRadius.circular(36),
                  child: Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      key,
                      style: AppTextStyle.heading1.copyWith(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
