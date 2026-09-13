import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/form_choice.dart';
import 'package:prokat/l10n/app_localizations.dart';

const jobScheduleDefaultHour = 16;
const jobScheduleDefaultMinute = 20;
const jobScheduleHorizonDays = 14;

enum JobScheduleMode { none, scheduled, asap }

DateTime jobScheduleToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime jobScheduleDefaultTimeOn(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
    jobScheduleDefaultHour,
    jobScheduleDefaultMinute,
  );
}

DateTime jobScheduleAsapWhen() {
  return DateTime.now().add(const Duration(minutes: 1));
}

Future<DateTime?> showJobDatePicker({
  required BuildContext context,
  required DateTime? current,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final today = jobScheduleToday();
  final initial = current == null || current.isBefore(today)
      ? today
      : current.isAfter(today.add(const Duration(days: jobScheduleHorizonDays)))
      ? today
      : current;

  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: today,
    lastDate: today.add(const Duration(days: jobScheduleHorizonDays)),
    helpText: l10n.dateAndTime,
    builder: (context, child) {
      final theme = Theme.of(context);
      if (theme.brightness != Brightness.light) return child!;
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            surfaceContainerHigh: AppTheme.white,
            onPrimary: AppTheme.white,
          ),
        ),
        child: child!,
      );
    },
  );
}

Future<DateTime?> showJobTimePicker({
  required BuildContext context,
  required DateTime date,
  required DateTime? current,
}) async {
  final seed = current ?? jobScheduleDefaultTimeOn(date);
  var draft = DateTime(date.year, date.month, date.day, seed.hour, seed.minute);

  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(draft),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: draft,
                  onDateTimeChanged: (value) => draft = value,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class JobScheduleSection extends StatelessWidget {
  const JobScheduleSection({
    super.key,
    required this.mode,
    required this.requiredHint,
    required this.selectedDate,
    required this.selectedTime,
    required this.locale,
    required this.onScheduled,
    required this.onAsap,
    required this.onPickDate,
    required this.onPickTime,
  });

  final JobScheduleMode mode;
  final String requiredHint;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final String locale;
  final VoidCallback onScheduled;
  final VoidCallback onAsap;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = selectedDate == null
        ? null
        : DateFormat('dd.MM.yyyy', locale).format(selectedDate!);
    final timeLabel = selectedTime == null
        ? null
        : DateFormat('HH:mm', locale).format(selectedTime!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredFieldLabel(
          title: l10n.dateAndTime,
          showRequired: mode == JobScheduleMode.none,
          requiredHint: requiredHint,
        ),
        const SizedBox(height: 10),
        ChoicePair(
          leftLabel: l10n.dateAndTime,
          rightLabel: l10n.asSoonAsPossible,
          leftSelected: mode == JobScheduleMode.scheduled,
          rightSelected: mode == JobScheduleMode.asap,
          onLeft: onScheduled,
          onRight: onAsap,
        ),
        if (mode == JobScheduleMode.scheduled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinePickerField(
                  label: l10n.selectDate,
                  value: dateLabel,
                  icon: Icons.calendar_today_outlined,
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinePickerField(
                  label: l10n.selectTime,
                  value: timeLabel,
                  icon: Icons.access_time,
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
