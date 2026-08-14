import 'package:prokat/features/bookings/models/booking_lookup.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/client_history_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_history_bookings_provider.dart';
import 'package:prokat/features/bookings/utils/booking_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

class BookingNotifier
    extends FamilyAsyncNotifier<BookingModel?, BookingLookup> {
  @override
  Future<BookingModel?> build(BookingLookup arg) async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) return null;

    //
    // 1. Search Active
    //

    if (arg.isOwner) {
      final active = ref.read(ownerActiveBookingsProvider);

      final booking = (active.asData?.value.items ?? []).findById(
        arg.bookingId,
      );

      if (booking != null) {
        return booking;
      }
    } else {
      final active = ref.read(clientActiveBookingsProvider);

      final booking = (active.asData?.value.items ?? []).findById(
        arg.bookingId,
      );

      if (booking != null) {
        return booking;
      }
    }

    //
    // 2. Search History
    //

    if (arg.isOwner) {
      final history = ref.read(ownerHistoryBookingsProvider);

      final booking = (history.asData?.value.items ?? []).findById(
        arg.bookingId,
      );

      if (booking != null) {
        return booking;
      }
    } else {
      final history = ref.read(clientHistoryBookingsProvider);

      final booking = (history.asData?.value.items ?? []).findById(
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

    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) return null;

    return null; // bookingService.getBookingById(arg.bookingId);
  }
}
