import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/state/client_history_bookings_notifier.dart';

final clientHistoryBookingsProvider =
    AsyncNotifierProvider<
      ClientHistoryBookingsNotifier,
      QueryState<BookingModel>
    >(ClientHistoryBookingsNotifier.new);
