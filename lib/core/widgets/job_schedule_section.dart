import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/widgets/form_choice.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

const jobScheduleDefaultHour = 16;
const jobScheduleDefaultMinute = 20;
const jobScheduleMinuteInterval = 10;

enum JobScheduleMode { none, scheduled, asap }

DateTime jobScheduleToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Last day of the month after [jobScheduleToday]'s month.
DateTime jobScheduleLastDate() {
  final today = jobScheduleToday();
  return DateTime(today.year, today.month + 2, 0);
}

/// Today, or tomorrow when no 10-minute slot remains today.
DateTime jobScheduleFirstSelectableDate({DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final earliest = jobScheduleCeilToMinuteInterval(n);
  if (jobScheduleIsSameDay(earliest, today)) return today;
  return today.add(const Duration(days: 1));
}

bool jobScheduleIsSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime jobScheduleCeilToMinuteInterval(
  DateTime value, {
  int interval = jobScheduleMinuteInterval,
}) {
  final truncated = DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
  );
  final rem = truncated.minute % interval;
  if (rem == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0) {
    return truncated;
  }
  final addMinutes = rem == 0 ? interval : interval - rem;
  return truncated.add(Duration(minutes: addMinutes));
}

DateTime jobScheduleEarliestTime({DateTime? now}) {
  return jobScheduleCeilToMinuteInterval(now ?? DateTime.now());
}

/// Snaps minutes to [jobScheduleMinuteInterval] and, for today, lifts past times.
DateTime jobScheduleResolveTimeOn(DateTime date, DateTime time) {
  var resolved = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute - (time.minute % jobScheduleMinuteInterval),
  );
  if (!jobScheduleIsSameDay(date, DateTime.now())) return resolved;

  final earliest = jobScheduleEarliestTime();
  if (!jobScheduleIsSameDay(earliest, date)) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      60 - jobScheduleMinuteInterval,
    );
  }
  if (resolved.isBefore(earliest)) return earliest;
  return resolved;
}

DateTime jobScheduleDefaultTimeOn(DateTime date) {
  return jobScheduleResolveTimeOn(
    date,
    DateTime(
      date.year,
      date.month,
      date.day,
      jobScheduleDefaultHour,
      jobScheduleDefaultMinute,
    ),
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
  final firstDate = jobScheduleFirstSelectableDate();
  final lastDate = jobScheduleLastDate();
  final initial = current == null || current.isBefore(firstDate)
      ? firstDate
      : current.isAfter(lastDate)
      ? firstDate
      : DateTime(current.year, current.month, current.day);

  return AppBottomSheet.show<DateTime>(
    context,
    title: l10n.dateAndTime,
    contentBuilder: (context) {
      return _JobDatePickerContent(
        initialDate: initial,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

Future<DateTime?> showJobTimePicker({
  required BuildContext context,
  required DateTime date,
  required DateTime? current,
}) async {
  final day = DateTime(date.year, date.month, date.day);
  final seed = current ?? jobScheduleDefaultTimeOn(day);
  var draft = jobScheduleResolveTimeOn(day, seed);
  final isToday = jobScheduleIsSameDay(day, DateTime.now());
  final earliest = jobScheduleEarliestTime();
  final minimumDate = isToday && jobScheduleIsSameDay(earliest, day)
      ? earliest
      : null;

  final l10n = AppLocalizations.of(context)!;
  return AppBottomSheet.show<DateTime>(
    context,
    title: l10n.dateAndTime,
    contentBuilder: (context) {
      final material = MaterialLocalizations.of(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppDimens.s24$xl,
        children: [
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              minuteInterval: jobScheduleMinuteInterval,
              initialDateTime: draft,
              minimumDate: minimumDate,
              onDateTimeChanged: (value) {
                draft = DateTime(
                  day.year,
                  day.month,
                  day.day,
                  value.hour,
                  value.minute,
                );
              },
            ),
          ),
          Row(
            spacing: AppDimens.s12$md,
            children: [
              Expanded(
                child: AppOutlinedButton(
                  title: material.cancelButtonLabel,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: AppElevatedButton(
                  title: material.okButtonLabel,
                  onTap: () => Navigator.of(context).pop(draft),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _JobDatePickerContent extends StatefulWidget {
  const _JobDatePickerContent({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_JobDatePickerContent> createState() => _JobDatePickerContentState();
}

class _JobDatePickerContentState extends State<_JobDatePickerContent> {
  late DateTime _visibleMonth;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  bool get _canGoPrev {
    final prev = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final prevLast = DateTime(prev.year, prev.month + 1, 0);
    return !prevLast.isBefore(widget.firstDate);
  }

  bool get _canGoNext {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return !next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    if (delta < 0 && !_canGoPrev) return;
    if (delta > 0 && !_canGoNext) return;
    setState(() => _visibleMonth = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final material = MaterialLocalizations.of(context);
    final monthLabel = DateFormat.yMMMM(locale).format(_visibleMonth);

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    // Monday-based week index (0 = Mon … 6 = Sun), matching Material RU calendars.
    final leadingEmpty = (firstOfMonth.weekday + 6) % 7;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final weekdayLabels = List.generate(7, (index) {
      // 2024-01-01 is Monday.
      final day = DateTime(2024, 1, 1 + index);
      return DateFormat.E(locale).format(day);
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat.MMMEd(locale).format(_selected),
          style: AppFonts.headingM(context)
              .copyWith(color: context.colors.text.primary),
        ),
        const SizedBox(height: AppDimens.s12$md),
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AppIconButton(
              onTap: _canGoPrev ? () => _shiftMonth(-1) : null,
              icon: Icons.chevron_left,
            ),
            AppIconButton(
              onTap: _canGoNext ? () => _shiftMonth(1) : null,
              icon: Icons.chevron_right,
            ),
          ],
        ),
        const SizedBox(height: AppDimens.s04$xs),
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingEmpty + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }
            final day = index - leadingEmpty + 1;
            final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
            final enabled =
                !date.isBefore(widget.firstDate) &&
                !date.isAfter(widget.lastDate);
            final selected = enabled && jobScheduleIsSameDay(date, _selected);

            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: enabled ? () => setState(() => _selected = date) : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? colorScheme.primary : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? context.colors.text.white
                          : enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.28),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppDimens.s08$sm),
        Row(
          spacing: AppDimens.s12$md,
          children: [
            Expanded(
              child: AppOutlinedButton(
                title: material.cancelButtonLabel,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: AppElevatedButton(
                title: material.okButtonLabel,
                onTap: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
