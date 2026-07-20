import 'package:prokat/features/bookings/models/booking_lookup.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/client_history_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_history_bookings_provider.dart';
import 'package:prokat/features/bookings/utils/booking_extensions.dart';
import 'package:riverpod/riverpod.dart';

class BookingNotifier
    extends FamilyAsyncNotifier<BookingModel?, BookingLookup> {
  @override
  Future<BookingModel?> build(BookingLookup arg) async {
    //
    // 1. Search Active
    //

    if (arg.isOwner) {
      final active = ref.read(ownerActiveBookingsProvider);

      final booking = (active.valueOrNull?.items ?? []).findById(arg.bookingId);

      if (booking != null) {
        return booking;
      }
    } else {
      final active = ref.read(clientActiveBookingsProvider);

      final booking = (active.valueOrNull?.items ?? []).findById(arg.bookingId);

      if (booking != null) {
        return booking;
      }
    }

    //
    // 2. Search History
    //

    if (arg.isOwner) {
      final history = ref.read(ownerHistoryBookingsProvider);

      final booking = (history.valueOrNull?.items ?? []).findById(
        arg.bookingId,
      );

      if (booking != null) {
        return booking;
      }
    } else {
      final history = ref.read(clientHistoryBookingsProvider);

      final booking = (history.valueOrNull?.items ?? []).findById(
        arg.bookingId,
      );

      if (booking != null) {
        return booking;
      }
    }

    //
    // 3. Fetch From API
    //

    // final bookingService = ref.read(bookingServiceProvider);

    return null; // bookingService.getBookingById(arg.bookingId);
  }
}
