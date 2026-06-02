DateTime get initialTargetDateTime {
  final now = DateTime.now();

  // 1. Check if we need to add 30 extra minutes because we are too close to the hour boundary
  if (now.minute >= 30) {
    // If it's 10:35, we round up to 11:00, then add 30 mins -> 11:30
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    return nextHour.add(const Duration(minutes: 30));
  } else {
    // If it's 10:15, we just round up to the full hour -> 11:00
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }
}