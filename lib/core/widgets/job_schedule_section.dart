import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/widgets/form_choice.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

const jobScheduleDefaultHour = 16;
const jobScheduleDefaultMinute = 20;
const jobScheduleMinuteInterval = 10;

/// Cupertino time wheel magnifies the centered row by 2.35 / 2.1.
const _timeWheelCenterMagnification = 2.35 / 2.1;

/// Colon sits between the wheels, a step paler than the digit color.
const _timeSeparatorOpacity = 0.55;

/// Manrope ExtraBold draws ":" this far below the digit ink center, in ems.
const _timeSeparatorLiftEm = 180 / 2000;

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
    title: l10n.date,
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
    title: l10n.time,
    contentBuilder: (context) {
      final material = MaterialLocalizations.of(context);
      final digitStyle = AppFonts.headingL(context);
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppDimens.s24$xl,
        children: [
          SizedBox(
            height: 216,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CupertinoTheme(
                  data: CupertinoTheme.of(context).copyWith(
                    textTheme: CupertinoTheme.of(context).textTheme
                        .copyWith(dateTimePickerTextStyle: digitStyle),
                  ),
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
                IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      -digitStyle.fontSize! *
                          _timeSeparatorLiftEm *
                          _timeWheelCenterMagnification,
                    ),
                    child: Transform.scale(
                      scale: _timeWheelCenterMagnification,
                      child: Text(
                        ':',
                        style: digitStyle.copyWith(
                          color: context.colors.text.main.withValues(
                            alpha: _timeSeparatorOpacity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
  static const _gridSpacing = 4.0;
  static const _weekRows = 6;

  late final List<DateTime> _months;
  late final PageController _pages;
  late DateTime _selected;
  late int _page;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _months = _monthsBetween(widget.firstDate, widget.lastDate);
    final initial = DateTime(_selected.year, _selected.month);
    final index = _months.indexWhere(
      (month) => month.year == initial.year && month.month == initial.month,
    );
    _page = index < 0 ? 0 : index;
    _pages = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  DateTime get _visibleMonth => _months[_page];

  bool get _canGoPrev => _page > 0;

  bool get _canGoNext => _page < _months.length - 1;

  void _shiftMonth(int delta) {
    final next = _page + delta;
    if (next < 0 || next >= _months.length) return;
    _pages.animateToPage(
      next,
      duration: AppDimens.defaultAnimationDuration,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final material = MaterialLocalizations.of(context);
    final monthLabel = DateFormat.yMMMM(locale).format(_visibleMonth);

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
              child: Text(monthLabel, style: AppFonts.headingS(context)),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final cell =
                (constraints.maxWidth -
                    _gridSpacing * (DateTime.daysPerWeek - 1)) /
                DateTime.daysPerWeek;
            final height =
                cell * (_weekRows + 1) +
                _gridSpacing * (_weekRows - 1) +
                AppDimens.s08$sm;
            return SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pages,
                itemCount: _months.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  return _MonthPage(
                    month: _months[index],
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    selected: _selected,
                    spacing: _gridSpacing,
                    locale: locale,
                    onSelect: (date) => setState(() => _selected = date),
                  );
                },
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

List<DateTime> _monthsBetween(DateTime first, DateTime last) {
  final start = DateTime(first.year, first.month);
  final end = DateTime(last.year, last.month);
  final months = <DateTime>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    months.add(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  if (months.isEmpty) months.add(start);
  return months;
}

class _MonthPage extends StatelessWidget {
  const _MonthPage({
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.selected,
    required this.spacing,
    required this.locale,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime selected;
  final double spacing;
  final String locale;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weekendFill = context.colors.background.dangerSoft;
    final firstOfMonth = DateTime(month.year, month.month);
    // Monday-based week index (0 = Mon … 6 = Sun), matching Material RU calendars.
    final leadingEmpty = (firstOfMonth.weekday + 6) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekdayLabels = List.generate(DateTime.daysPerWeek, (index) {
      // 2024-01-01 is Monday.
      return DateFormat.E(locale).format(DateTime(2024, 1, 1 + index));
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = DateTime.daysPerWeek;
        final cell = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Stack(
          children: [
            for (var index = 0; index < columns; index++)
              if (_isWeekendColumn(index))
                Positioned(
                  left: index * (cell + spacing),
                  width: cell,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(color: weekendFill),
                ),
            Column(
              children: [
                Row(
                  spacing: spacing,
                  children: [
                    for (final label in weekdayLabels)
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Center(
                            child: Text(
                              label,
                              style: AppFonts.body16SemiBold(
                                context,
                              ).copyWith(color: context.colors.text.secondary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimens.s08$sm),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: leadingEmpty + daysInMonth,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemBuilder: (context, index) {
                      if (index < leadingEmpty) return const SizedBox.shrink();
                      final day = index - leadingEmpty + 1;
                      final date = DateTime(month.year, month.month, day);
                      final enabled =
                          !date.isBefore(firstDate) && !date.isAfter(lastDate);
                      final isSelected =
                          enabled && jobScheduleIsSameDay(date, selected);

                      return InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: enabled ? () => onSelect(date) : null,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: isSelected
                                  ? AppFonts.headingS(
                                      context,
                                    ).copyWith(color: context.colors.text.white)
                                  : enabled
                                  ? AppFonts.headingS(context)
                                  : AppFonts.headingS(context).copyWith(
                                      color: context.colors.text.main
                                          .withValues(alpha: 0.28),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Monday-based column: 0 = Mon … 5 = Sat, 6 = Sun.
bool _isWeekendColumn(int mondayIndex) => mondayIndex >= 5;

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
  final Future<void> Function() onPickDate;
  final Future<void> Function() onPickTime;

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
        const SizedBox(height: AppDimens.inputLabelGap),
        ChoicePair(
          leftLabel: l10n.jobScheduleSet,
          rightLabel: l10n.jobScheduleNearest,
          leftSelected: mode == JobScheduleMode.scheduled,
          rightSelected: mode == JobScheduleMode.asap,
          onLeft: onScheduled,
          onRight: onAsap,
        ),
        AppReveal(
          visible: mode == JobScheduleMode.scheduled,
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimens.s16$base),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: OutlinePickerField(
                    label: l10n.selectDate,
                    value: dateLabel,
                    isRequired: true,
                    icon: Icons.calendar_today_outlined,
                    onTap: onPickDate,
                  ),
                ),
                const SizedBox(width: AppDimens.s12$md),
                Expanded(
                  child: OutlinePickerField(
                    label: l10n.selectTime,
                    value: timeLabel,
                    isRequired: true,
                    icon: Icons.access_time,
                    onTap: onPickTime,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
