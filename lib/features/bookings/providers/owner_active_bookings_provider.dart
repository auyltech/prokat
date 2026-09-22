import 'dart:async';

import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/bookings/notifiers/owner_active_bookings_notifier.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ownerActiveBookingsProvider =
    AsyncNotifierProvider<
      OwnerActiveBookingsNotifier,
      QueryState<BookingModel>
    >(OwnerActiveBookingsNotifier.new);

/// A new order, or the owner's confirm / reject, moves the orders badge.
void refreshOwnerOrderBadge(Ref ref) {
  refreshNavigationCounts(ref);
  if (ref.exists(ownerActiveBookingsProvider)) {
    unawaited(ref.read(ownerActiveBookingsProvider.notifier).refresh());
  }
}

bool notificationRefreshesOwnerOrderBadge(NotificationType type) {
  return type == NotificationType.bookingCreated ||
      type == NotificationType.bookingConfirmed ||
      type == NotificationType.bookingRejected ||
      type == NotificationType.bookingCancelled ||
      type == NotificationType.bookingAccepted;
}
