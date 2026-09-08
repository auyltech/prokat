import 'package:prokat/l10n/app_localizations.dart';

class TimeBreakdown {
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  const TimeBreakdown({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  String format(AppLocalizations l10n) {
    final parts = <String>[];

    if (days > 0) {
      parts.add(l10n.durationDays(days));
    }

    if (hours > 0) {
      parts.add(l10n.durationHours(hours));
    }

    if (minutes > 0 || parts.isEmpty) {
      parts.add(l10n.durationMinutes(minutes));
    }

    if (days == 0 && hours == 0 && minutes == 0 && seconds > 0 ||
        parts.isEmpty) {
      parts.add(l10n.durationSeconds(seconds));
    }

    return parts.join(', ');
  }
}

TimeBreakdown getTimeBreakDown(int? totalSeconds) {
  if (totalSeconds == null || totalSeconds <= 0) {
    return const TimeBreakdown(days: 0, hours: 0, minutes: 0, seconds: 0);
  }

  final duration = Duration(seconds: totalSeconds);

  return TimeBreakdown(
    days: duration.inDays,
    hours: duration.inHours.remainder(24),
    minutes: duration.inMinutes.remainder(60),
    seconds: duration.inSeconds.remainder(60),
  );
}

String getTimeString(int? totalSeconds, AppLocalizations l10n) {
  if (totalSeconds == null || totalSeconds < 0) {
    return l10n.invalidSecondsValue;
  }

  return getTimeBreakDown(totalSeconds).format(l10n);
}
