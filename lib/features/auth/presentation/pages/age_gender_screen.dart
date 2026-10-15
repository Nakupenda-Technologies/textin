import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../models/registration_details.dart';
import '../../notifier/registration_notifier.dart';
import '../../validators.dart';
import '../widgets/auth_form_scaffold.dart';

class AgeGenderScreen extends ConsumerStatefulWidget {
  const AgeGenderScreen({super.key});

  @override
  ConsumerState<AgeGenderScreen> createState() => _AgeGenderScreenState();
}

class _AgeGenderScreenState extends ConsumerState<AgeGenderScreen> {
  final _dateOfBirthText = TextEditingController();
  final _genderText = TextEditingController();
  final _dateFormat = DateFormat('d MMMM y');
  DateTime? _dateOfBirth;
  Gender? _gender;

  @override
  void dispose() {
    _dateOfBirthText.dispose();
    _genderText.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final latest = AuthValidators.latestAllowedBirthDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? latest,
      firstDate: DateTime(1900),
      lastDate: latest,
      helpText: 'Select your date of birth',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    ref
        .read(registrationNotifierProvider.notifier)
        .clearError(RegistrationField.dateOfBirth);
    setState(() {
      _dateOfBirth = picked;
      _dateOfBirthText.text = _dateFormat.format(picked);
    });
  }

  Future<void> _pickGender() async {
    final picked = await showModalBottomSheet<Gender>(
      context: context,
      showDragHandle: true,
      builder: (context) => _GenderSheet(selected: _gender),
    );
    if (picked == null || !mounted) return;
    ref
        .read(registrationNotifierProvider.notifier)
        .clearError(RegistrationField.gender);
    setState(() {
      _gender = picked;
      _genderText.text = picked.label;
    });
  }

  Future<void> _submit() async {
    final outcome = await ref
        .read(registrationNotifierProvider.notifier)
        .submitAgeGender(dateOfBirth: _dateOfBirth, gender: _gender);
    if (!mounted || outcome is! RegistrationContinues) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.routeForRegistrationStep(outcome.nextStep),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationNotifierProvider);
    final enabled = !state.isSubmitting;
    final iconColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);

    return AuthFormScaffold(
      step: 3,
      title: 'Age & Gender',
      subtitle: 'Fill in your age and gender',
      action: AppButton(
        label: 'Next Step',
        isLoading: state.isSubmitting,
        onPressed: _dateOfBirth != null && _gender != null ? _submit : null,
      ),
      children: [
        AppTextField(
          label: 'Date of Birth',
          hintText: 'Select your date of birth',
          controller: _dateOfBirthText,
          readOnly: true,
          enabled: enabled,
          onTap: _pickDateOfBirth,
          errorText: state.errorFor(RegistrationField.dateOfBirth),
          helperText: state.errorFor(RegistrationField.dateOfBirth) == null
              ? 'You must be ${AuthValidators.minimumAge} or older to join.'
              : null,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Gender',
          hintText: 'Select Your Gender',
          controller: _genderText,
          readOnly: true,
          enabled: enabled,
          onTap: _pickGender,
          errorText: state.errorFor(RegistrationField.gender),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: iconColor),
          ),
        ),
      ],
    );
  }
}

class _GenderSheet extends StatelessWidget {
  const _GenderSheet({required this.selected});

  final Gender? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Select your gender',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final gender in Gender.values)
              ListTile(
                title: Text(
                  gender.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: gender == selected
                    ? const Icon(Icons.check_rounded, color: AppTheme.textred)
                    : null,
                selected: gender == selected,
                onTap: () => Navigator.of(context).pop(gender),
              ),
          ],
        ),
      ),
    );
  }
}
