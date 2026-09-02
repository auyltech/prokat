import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/bookings/models/work_status.dart';

void main() {
  test('started can pause or complete, not cancel', () {
    expect(nextWorkStatuses(WorkStatus.started), [
      WorkStatus.stopped,
      WorkStatus.completed,
    ]);
    expect(canTransition(WorkStatus.started, WorkStatus.cancelled), isFalse);
    expect(canTransition(WorkStatus.started, WorkStatus.started), isFalse);
  });

  test('stopped can resume or complete', () {
    expect(nextWorkStatuses(WorkStatus.stopped), [
      WorkStatus.started,
      WorkStatus.completed,
    ]);
    expect(canTransition(WorkStatus.stopped, WorkStatus.stopped), isFalse);
  });

  test('cannot complete before work has started', () {
    expect(canTransition(WorkStatus.pending, WorkStatus.completed), isFalse);
    expect(canTransition(WorkStatus.onSite, WorkStatus.completed), isFalse);
    expect(canTransition(WorkStatus.started, WorkStatus.completed), isTrue);
  });
}
