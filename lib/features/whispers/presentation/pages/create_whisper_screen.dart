import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../notifier/my_whispers_notifier.dart';

final _scheduleFormat = DateFormat('EEE, MMM d · h:mm a');

class CreateWhisperScreen extends ConsumerStatefulWidget {
  const CreateWhisperScreen({super.key});

  @override
  ConsumerState<CreateWhisperScreen> createState() =>
      _CreateWhisperScreenState();
}

class _CreateWhisperScreenState extends ConsumerState<CreateWhisperScreen> {
  final _titleController = TextEditingController();
  bool _isPrivate = false;
  DateTime? _scheduledAt;
  bool _isSaving = false;

  bool get _scheduleInPast => _scheduledAt?.isBefore(DateTime.now()) ?? false;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && !_scheduleInPast;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateUtils.dateOnly(now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final scheduledAt = _scheduledAt;
    final failure = await ref
        .read(myWhispersNotifierProvider.notifier)
        .create(
          title: _titleController.text.trim(),
          isPrivate: _isPrivate,
          scheduledAt: scheduledAt,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (failure != null) {
      AppToast.failure("Couldn't create the whisper", failure);
      return;
    }
    AppToast.show(
      scheduledAt == null
          ? 'Whisper saved as a draft'
          : 'Whisper scheduled for ${_scheduleFormat.format(scheduledAt)}',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduledAt = _scheduledAt;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.chatAreaBg,
      appBar: AppBar(title: const Text('New whisper')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              label: 'Title',
              hintText: 'What do you want to talk about?',
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Private'),
              subtitle: const Text('Only people you invite can join'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Schedule for later'),
              subtitle: Text(
                scheduledAt == null
                    ? 'Off: saved as a draft'
                    : _scheduleFormat.format(scheduledAt),
              ),
              value: scheduledAt != null,
              onChanged: (value) =>
                  value ? _pickSchedule() : setState(() => _scheduledAt = null),
            ),
            if (scheduledAt != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickSchedule,
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('Change time'),
                ),
              ),
            if (_scheduleInPast)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Pick a time in the future.',
                  style: AppTextStyle.bodySecondary.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Create whisper',
              isLoading: _isSaving,
              onPressed: _canSubmit && !_isSaving ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
