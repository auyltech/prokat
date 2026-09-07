import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/requests/state/request_lifetime.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7, 12);

  test('hides empty or zero capacity', () {
    expect(hasVisibleRequestCapacity(null), isFalse);
    expect(hasVisibleRequestCapacity(''), isFalse);
    expect(hasVisibleRequestCapacity('0'), isFalse);
    expect(hasVisibleRequestCapacity('10'), isTrue);
  });

  test('counts 24 hours from publication and clamps clock skew', () {
    expect(requestLifetimeRemaining(now, now: now), requestLifetime);
    expect(
      requestLifetimeRemaining(
        now.subtract(const Duration(hours: 5)),
        now: now,
      ).inHours,
      19,
    );
    expect(
      requestLifetimeRemaining(
        now.subtract(const Duration(hours: 24)),
        now: now,
      ),
      Duration.zero,
    );
    expect(
      requestLifetimeRemaining(now.add(const Duration(days: 400)), now: now),
      requestLifetime,
    );
  });

  test('uses hours until the last hour, then minutes', () {
    const almostHour = Duration(minutes: 59);
    expect(requestLifetimeHoursLeft(const Duration(hours: 24)), 24);
    expect(requestLifetimeHoursLeft(almostHour), 0);
    expect(requestLifetimeMinutesLeft(almostHour), 59);
    expect(requestLifetimeMinutesLeft(const Duration(seconds: 20)), 1);
  });
}
