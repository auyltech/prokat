import 'package:prokat/features/bookings/models/booking_lookup.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/notifiers/booking_notifier.dart';
import 'package:riverpod/riverpod.dart';

final bookingProvider =
    AsyncNotifierProvider.family<BookingNotifier, BookingModel?, BookingLookup>(
      BookingNotifier.new,
    );
