import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';

void main() {
  group('jobScheduleCeilToMinuteInterval', () {
    test('keeps exact interval', () {
      final value = DateTime(2026, 9, 14, 7, 10);
      expect(jobScheduleCeilToMinuteInterval(value), value);
    });

    test('rounds up to next 10 minutes', () {
      expect(
        jobScheduleCeilToMinuteInterval(DateTime(2026, 9, 14, 7, 3)),
        DateTime(2026, 9, 14, 7, 10),
      );
      expect(
        jobScheduleCeilToMinuteInterval(DateTime(2026, 9, 14, 7, 11)),
        DateTime(2026, 9, 14, 7, 20),
      );
    });

    test('rolls to next hour', () {
      expect(
        jobScheduleCeilToMinuteInterval(DateTime(2026, 9, 14, 7, 51)),
        DateTime(2026, 9, 14, 8, 0),
      );
    });
  });

  group('jobScheduleLastDate', () {
    test('reaches next month from mid-month', () {
      // lastDate is end of month after today — must include October when today is Sept.
      final last = jobScheduleLastDate();
      final today = jobScheduleToday();
      expect(last.isAfter(DateTime(today.year, today.month + 1, 0)), isTrue);
      expect(last, DateTime(today.year, today.month + 2, 0));
    });
  });

  group('jobScheduleFirstSelectableDate', () {
    test('is today when slots remain', () {
      final now = DateTime(2026, 9, 14, 7, 3);
      expect(jobScheduleFirstSelectableDate(now: now), DateTime(2026, 9, 14));
    });

    test('is tomorrow when no slots remain today', () {
      final now = DateTime(2026, 9, 14, 23, 55);
      expect(jobScheduleFirstSelectableDate(now: now), DateTime(2026, 9, 15));
    });
  });

  group('jobScheduleResolveTimeOn', () {
    test('snaps minutes down to interval on future day', () {
      final date = DateTime(2099, 1, 2);
      expect(
        jobScheduleResolveTimeOn(date, DateTime(2099, 1, 2, 8, 36)),
        DateTime(2099, 1, 2, 8, 30),
      );
    });
  });
}
