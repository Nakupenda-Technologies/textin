import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/notifier/session_notifier.dart';
import '../../notifier/my_whispers_notifier.dart';
import '../../notifier/whisper_room_notifier.dart';
import 'whisper_live_room_sheet.dart';

final _scheduledFormat = DateFormat('MMM d, h:mm a');

Future<void> showCreateWhisperSheet(BuildContext context) => _showWhisperSheet(
  context,
  heightFactor: .62,
  child: const _CreateWhisperSheetContent(),
);

Future<void> _showWhisperSheet(
  BuildContext context, {
  double? heightFactor,
  required Widget child,
}) {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .45),
    builder: (ctx) {
      final keyboard = MediaQuery.of(ctx).viewInsets.bottom;
      final height = MediaQuery.of(ctx).size.height;
      return Container(
        height: heightFactor == null
            ? null
            : (height * heightFactor + keyboard).clamp(0.0, height * .92),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: child,
      );
    },
  );
}

class _CreateWhisperSheetContent extends ConsumerStatefulWidget {
  const _CreateWhisperSheetContent();

  @override
  ConsumerState<_CreateWhisperSheetContent> createState() =>
      _CreateWhisperSheetContentState();
}

class _CreateWhisperSheetContentState
    extends ConsumerState<_CreateWhisperSheetContent> {
  final _titleController = TextEditingController();
  bool? _isPrivate;
  bool _isStarting = false;

  String get _title => _titleController.text.trim();

  bool get _canSchedule =>
      _title.isNotEmpty && _isPrivate != null && !_isStarting;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final title = _title;
    if (title.isEmpty) {
      AppToast.error('Missing title', 'Please enter a whisper title.');
      return;
    }
    setState(() => _isStarting = true);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final notifier = ref.read(myWhispersNotifierProvider.notifier);
    final created = await notifier.create(
      title: title,
      isPrivate: _isPrivate ?? false,
    );
    final id = created.fold((failure) {
      AppToast.failure("Couldn't create the whisper", failure);
      return null;
    }, (id) => id);
    final failure = id == null ? null : await notifier.start(id);
    if (!mounted) return;
    setState(() => _isStarting = false);
    if (id == null) return;
    if (failure != null) {
      AppToast.failure("Couldn't start the whisper", failure);
      return;
    }

    final user = ref.read(currentUserProvider);
    Navigator.pop(context);
    if (!rootNavigator.mounted) return;
    openWhisperRoom(
      rootNavigator.context,
      WhisperRoomArgs(
        whisperId: id,
        title: title,
        hostName: user?.displayName ?? '',
        hostAvatarUrl: user?.profilePicture,
        isHost: true,
      ),
    );
  }

  void _schedule() {
    final title = _title;
    final isPrivate = _isPrivate ?? false;
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Navigator.pop(context);
    _showWhisperSheet(
      rootContext,
      child: _ScheduleSheetContent(title: title, isPrivate: isPrivate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        children: [
          const SizedBox(height: 2),
          const _SheetHandle(),
          const SizedBox(height: 16),
          Text(
            'Create New Whisper',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Whisper',
                    hintText: 'ie Late night chill section',
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _VisibilityField(
                    value: _isPrivate,
                    onChanged: (value) => setState(() => _isPrivate = value),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _PrimaryButton(
            label: 'Start',
            isLoading: _isStarting,
            onPressed: _isStarting ? null : _start,
          ),
          const SizedBox(height: 12),
          _ScheduleButton(onPressed: _canSchedule ? _schedule : null),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ScheduleSheetContent extends ConsumerStatefulWidget {
  const _ScheduleSheetContent({required this.title, required this.isPrivate});

  final String title;
  final bool isPrivate;

  @override
  ConsumerState<_ScheduleSheetContent> createState() =>
      _ScheduleSheetContentState();
}

class _ScheduleSheetContentState extends ConsumerState<_ScheduleSheetContent> {
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _isSaving = false;

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _time = picked;
      _timeController.text = picked.format(context);
    });
  }

  Future<void> _confirm() async {
    final date = _date;
    final time = _time;
    if (date == null || time == null) {
      AppToast.error('Incomplete', 'Please select date and time.');
      return;
    }
    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (scheduledAt.isBefore(DateTime.now())) {
      AppToast.error('Pick a later time', 'Choose a time in the future.');
      return;
    }

    setState(() => _isSaving = true);
    final result = await ref
        .read(myWhispersNotifierProvider.notifier)
        .create(
          title: widget.title,
          isPrivate: widget.isPrivate,
          scheduledAt: scheduledAt,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.fold(
      (failure) => AppToast.failure("Couldn't schedule the whisper", failure),
      (_) {
        AppToast.show(
          'Whisper scheduled for ${_scheduledFormat.format(scheduledAt)}',
        );
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 2),
          const _SheetHandle(),
          const SizedBox(height: 14),
          Text(
            'Save whisper for later',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Date',
            hintText: 'Select date',
            controller: _dateController,
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: 22),
          AppTextField(
            label: 'Time',
            hintText: 'Select time',
            controller: _timeController,
            readOnly: true,
            suffixIcon: const Icon(Icons.access_time_rounded),
            onTap: _pickTime,
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Schedule',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _confirm,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _VisibilityField extends StatelessWidget {
  const _VisibilityField({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(35),
      borderSide: BorderSide(
        color: isDark ? AppTheme.darkBorder : AppTheme.btnborder,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<bool>(
          initialValue: value,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: theme.colorScheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: onSurface.withValues(alpha: 0.75),
          ),
          hint: Text(
            'Select visibility',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          items: const [
            DropdownMenuItem(value: false, child: Text('Public')),
            DropdownMenuItem(value: true, child: Text('Private')),
          ],
          decoration: InputDecoration(
            constraints: const BoxConstraints(minHeight: 50),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            filled: true,
            fillColor: isDark ? AppTheme.darkSurface : AppTheme.surface,
            border: border,
            enabledBorder: border,
            focusedBorder: border,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.textred,
          disabledBackgroundColor: AppTheme.textred.withValues(alpha: .6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14.8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _ScheduleButton extends StatelessWidget {
  const _ScheduleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = onPressed == null
        ? cs.onSurface.withValues(alpha: .35)
        : cs.onSurface;

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.divider2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Schedule',
              style: TextStyle(
                fontSize: 14.8,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: color.withValues(alpha: .75),
            ),
          ],
        ),
      ),
    );
  }
}
