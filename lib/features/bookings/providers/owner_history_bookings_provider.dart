import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/state/owner_history_bookings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ownerHistoryBookingsProvider =
    AsyncNotifierProvider<
      OwnerHistoryBookingsNotifier,
      QueryState<BookingModel>
    >(OwnerHistoryBookingsNotifier.new);
