import 'package:prokat/features/bookings/models/booking_status.dart';

const activeBookingStatuses = <BookingStatus>{
  BookingStatus.draft,
  BookingStatus.created,
  BookingStatus.confirmed,
};

const historyBookingStatuses = <BookingStatus>{
  BookingStatus.cancelled,
  BookingStatus.failed,
  BookingStatus.rejected,
  BookingStatus.completed,
  BookingStatus.reviewed,
};

bool isActiveBookingStatus(BookingStatus status) {
  return activeBookingStatuses.contains(status);
}

bool isHistoryBookingStatus(BookingStatus status) {
  return historyBookingStatuses.contains(status);
}
