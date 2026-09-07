const requestLifetime = Duration(hours: 24);

bool hasVisibleRequestCapacity(String? capacity) {
  final trimmed = capacity?.trim() ?? '';
  if (trimmed.isEmpty) return false;
  final parsed = num.tryParse(trimmed.replaceAll(',', '.'));
  if (parsed != null && parsed == 0) return false;
  return true;
}

Duration requestLifetimeRemaining(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) return Duration.zero;

  final created = createdAt.toUtc();
  final clock = (now ?? DateTime.now()).toUtc();

  if (created.isAfter(clock)) {
    return requestLifetime;
  }

  final elapsed = clock.difference(created);
  if (elapsed >= requestLifetime) return Duration.zero;
  return requestLifetime - elapsed;
}

int requestLifetimeHoursLeft(Duration remaining) => remaining.inHours;

int requestLifetimeMinutesLeft(Duration remaining) {
  final minutes = remaining.inMinutes;
  if (minutes <= 0 && remaining > Duration.zero) return 1;
  return minutes;
}
