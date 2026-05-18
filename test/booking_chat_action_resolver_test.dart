import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_resolver.dart';
import 'package:prokat/features/locations/models/location_model.dart';

BookingModel _booking({
  required String status,
  WorkStatus workStatus = WorkStatus.pending,
}) {
  return BookingModel(
    id: 'b1',
    status: status,
    workStatus: workStatus,
    price: 1000,
    priceRate: 'per hour',
    location: LocationModel(
      service: 'ADDRESS',
      street: 'Main',
      city: 'Atyrau',
      country: 'KZ',
      longitude: 0,
      latitude: 0,
    ),
  );
}

void main() {
  const resolver = BookingChatActionResolver();

  test('Owner CREATED: accept primary + reject secondary', () {
    final resolution = resolver.resolve(
      booking: _booking(status: BookingStatus.created.name),
      role: BookingChatRole.owner,
      now: DateTime(2026, 1, 1),
    );

    expect(resolution.primaryAction?.id, BookingChatActionId.acceptBooking);
    expect(
      resolution.secondaryActions.first.id,
      BookingChatActionId.rejectBooking,
    );
  });

  test('Client CREATED: cancel primary', () {
    final resolution = resolver.resolve(
      booking: _booking(status: BookingStatus.created.name),
      role: BookingChatRole.client,
      now: DateTime(2026, 1, 1),
    );

    expect(resolution.primaryAction?.id, BookingChatActionId.cancelBooking);
  });

  test('Owner CONFIRMED + pending: update status primary', () {
    final resolution = resolver.resolve(
      booking: _booking(
        status: BookingStatus.confirmed.name,
        workStatus: WorkStatus.pending,
      ),
      role: BookingChatRole.owner,
      now: DateTime(2026, 1, 1),
    );

    expect(resolution.primaryAction?.id, BookingChatActionId.updateWorkStatus);
  });

  test('Client CONFIRMED + completed: confirm completion primary', () {
    final resolution = resolver.resolve(
      booking: _booking(
        status: BookingStatus.confirmed.name,
        workStatus: WorkStatus.completed,
      ),
      role: BookingChatRole.client,
      now: DateTime(2026, 1, 1),
    );

    expect(resolution.primaryAction?.id, BookingChatActionId.confirmCompletion);
  });

  test('Final COMPLETED: no actions', () {
    final resolution = resolver.resolve(
      booking: _booking(status: BookingStatus.completed.name),
      role: BookingChatRole.owner,
      now: DateTime(2026, 1, 1),
    );

    expect(resolution.primaryAction, isNull);
    expect(resolution.secondaryActions, isEmpty);
    expect(resolution.overflowActions, isEmpty);
  });

  test('Unknown status: safe fallback', () {
    final resolution = resolver.resolve(
      booking: _booking(status: 'SOMETHING_NEW'),
      role: BookingChatRole.owner,
      now: DateTime(2026, 1, 1),
    );

    expect(resolution.primaryAction, isNull);
    expect(resolution.secondaryActions, isEmpty);
  });
}
