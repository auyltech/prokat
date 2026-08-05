import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/notifiers/client_active_bookings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientActiveBookingsProvider =
    AsyncNotifierProvider<
      ClientActiveBookingsNotifier,
      QueryState<BookingModel>
    >(ClientActiveBookingsNotifier.new);
