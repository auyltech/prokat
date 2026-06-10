class TimeBreakdown {
  final int days;
  final int hours;
  final int minutes;

  const TimeBreakdown({
    required this.days,
    required this.hours,
    required this.minutes,
  });

  @override
  String toString() {
    final parts = <String>[];

    if (days > 0) {
      parts.add('$days ${days == 1 ? 'day' : 'days'}');
    }

    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hr' : 'hrs'}');
    }

    if (minutes > 0 || parts.isEmpty) {
      parts.add('$minutes min');
    }

    return parts.join(', ');
  }
}

TimeBreakdown getTimeBreakDown(int? totalSeconds) {
  if (totalSeconds == null || totalSeconds <= 0) {
    return const TimeBreakdown(days: 0, hours: 0, minutes: 0);
  }

  final duration = Duration(seconds: totalSeconds);

  return TimeBreakdown(
    days: duration.inDays,
    hours: duration.inHours.remainder(24),
    minutes: duration.inMinutes.remainder(60),
  );
}

String getTimeString(int? totalSeconds) {
  if (totalSeconds == null || totalSeconds <= 0) {
    return "Invalid Seconds Value";
  }

  return getTimeBreakDown(totalSeconds).toString();
}
