import 'package:prokat/features/bookings/models/booking_model.dart';

extension BookingSearch on List<BookingModel> {
  BookingModel? findById(String id) {
    for (final booking in this) {
      if (booking.id == id) {
        return booking;
      }
    }

    return null;
  }
}
