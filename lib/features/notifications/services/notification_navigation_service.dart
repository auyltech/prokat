import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';
import 'package:prokat/features/notifications/utils/notification_audience.dart';
import 'package:prokat/features/notifications/utils/notification_route_resolver.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';

export 'package:prokat/features/notifications/utils/notification_route_resolver.dart';

// TODO: fix route reslove
// Backend should send event, type, targetId,
// Flutter app should build route
// Save notification event and targetId, not route, remove current save route
class NotificationNavigationService {
  final Ref ref;
  final NotificationLocalStorage storage;

  NotificationNavigationService(this.ref, this.storage);

  bool get _isOwnerMode =>
      ref.read(appStartupProvider).routeState == AppStartupRouteState.owner;

  bool _opensOwnerShell(AppNotification notification) {
    return notificationOpensOwnerShell(
      type: notification.type,
      data: notification.data,
      isOwnerMode: _isOwnerMode,
    );
  }

  String notificationsHomeRoute() {
    return _isOwnerMode
        ? AppRoutes.ownerNotifications
        : AppRoutes.clientNotifications;
  }

  String resolveRoute(AppNotification notification) {
    return resolveNotificationRoute(
      notification: notification,
      opensOwner: _opensOwnerShell(notification),
      notificationsHome: notificationsHomeRoute(),
    );
  }

  Future<void> _applyShellForRoute(String route) async {
    final startup = ref.read(appStartupProvider).routeState;

    if (route.startsWith(AppRoutes.ownerMain) &&
        startup == AppStartupRouteState.client) {
      await ref.read(appStartupProvider.notifier).setOwnerMode();
    } else if (route.startsWith(AppRoutes.clientMain) &&
        startup == AppStartupRouteState.owner) {
      await ref.read(appStartupProvider.notifier).setClientMode();
    }
  }

  Future<void> navigate(AppNotification notification) async {
    final router = ref.read(routerProvider);
    final route = resolveRoute(notification);
    final goingOwner = route.startsWith(AppRoutes.ownerMain);

    final startup = ref.read(appStartupProvider).routeState;
    final session = ref.read(authProvider).session;

    if (notification.category == "BOOKING") {
      if (goingOwner) {
        unawaited(ref.read(ownerActiveBookingsProvider.notifier).invalidate());
      } else {
        unawaited(ref.read(clientActiveBookingsProvider.notifier).invalidate());
      }
    } else if (notification.category == "REQUEST") {
      if (goingOwner) {
        unawaited(ref.read(ownerActiveRequestsProvider.notifier).invalidate());
      } else {
        unawaited(ref.read(clientActiveRequestsProvider.notifier).invalidate());
      }
    }

    final isReady =
        startup == AppStartupRouteState.client ||
        startup == AppStartupRouteState.owner;

    if (!isReady) {
      await savePendingRoute(route);

      if (session == null) {
        final from = Uri.encodeComponent(route);
        router.go('${AppRoutes.login}?from=$from');
      }

      return;
    }

    await _applyShellForRoute(route);
    router.go(route);
  }

  Future<void> savePendingRoute(String route) async {
    await storage.savePendingRoute(route);
  }

  /// Applies a pending route saved while the shell was not ready.
  ///
  /// Only navigates routes previously built by [resolveRoute] (`/client…` or
  /// `/owner…`). Backend `route` / `deepLink` are never flushed.
  Future<void> flushPendingRouteIfAny() async {
    final route = await storage.readPendingRoute();

    if ((route ?? '').isEmpty) return;

    await storage.clearPendingRoute();

    if (!isTrustedNotificationAppRoute(route!)) return;

    final startup = ref.read(appStartupProvider).routeState;
    final isReady =
        startup == AppStartupRouteState.client ||
        startup == AppStartupRouteState.owner;

    if (!isReady) {
      await storage.savePendingRoute(route);
      return;
    }

    await _applyShellForRoute(route);
    ref.read(routerProvider).go(route);
  }
}
