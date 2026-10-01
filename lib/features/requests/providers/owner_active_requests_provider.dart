import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/state/owner_active_requests_notifier.dart';

final ownerActiveRequestsProvider =
    AsyncNotifierProvider.family<
      OwnerActiveRequestsNotifier,
      QueryState<RequestModel>,
      CatalogGroup
    >(OwnerActiveRequestsNotifier.new);

/// Feeds that a screen has already opened. Each catalog group is its own list.
List<OwnerActiveRequestsNotifier> loadedOwnerActiveRequestFeeds(Ref ref) {
  return [
    for (final group in CatalogGroup.values)
      if (ref.exists(ownerActiveRequestsProvider(group)))
        ref.read(ownerActiveRequestsProvider(group).notifier),
  ];
}

/// Request pushes must move the radar badge and the open inbox even when the
/// workflow socket missed the same event.
void refreshOwnerRequestFeed(Ref ref) {
  refreshNavigationCounts(ref);
  for (final feed in loadedOwnerActiveRequestFeeds(ref)) {
    unawaited(feed.refreshForNewRequest());
  }
}

bool notificationRefreshesOwnerRequestFeed(NotificationType type) {
  return type == NotificationType.requestCreated ||
      type == NotificationType.requestCancelled ||
      type == NotificationType.requestExpired;
}
