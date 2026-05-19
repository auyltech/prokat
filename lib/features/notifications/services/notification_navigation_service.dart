import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';

class NotificationNavigationService {
  final Ref ref;
  final NotificationLocalStorage storage;

  NotificationNavigationService(this.ref, this.storage);

  String _normalizedRole() {
    final role = ref.read(authProvider).session?.user?.role;
    return (role ?? '').trim().toUpperCase();
  }

  bool get _isOwnerRole => _normalizedRole() == 'OWNER';

  String notificationsHomeRoute() {
    return _isOwnerRole ? AppRoutes.ownerNotifications : AppRoutes.notifications;
  }

  String resolveRoute(AppNotification notification) {
    // Backend-provided route is optional; app decides best-effort.
    final candidate = (notification.route ?? '').trim();
    if (_isSafeBackendRoute(candidate)) {
      return candidate;
    }

    final type = notification.type.trim().toUpperCase();

    switch (type) {
      case 'CHAT_MESSAGE':
      case 'COUNTER_OFFER_CREATED':
      case 'COUNTER_OFFER_ACCEPTED':
        final chatId = (notification.chatId ?? '').trim();
        if (chatId.isNotEmpty) {
          return _isOwnerRole ? '${AppRoutes.ownerChat}/$chatId' : '${AppRoutes.chat}/$chatId';
        }
        return notificationsHomeRoute();

      case 'BOOKING_CREATED':
      case 'BOOKING_ACCEPTED':
      case 'BOOKING_REJECTED':
      case 'WORK_STATUS_UPDATED':
      case 'WORK_COMPLETED':
        // Booking details routes are currently inconsistent across client/owner;
        // Phase 1: route user to Orders list.
        return _isOwnerRole ? AppRoutes.ownerBookings : AppRoutes.clientOrders;

      case 'EQUIPMENT_APPROVED':
      case 'EQUIPMENT_REJECTED':
        final equipmentId = (notification.equipmentId ?? '').trim();
        if (_isOwnerRole && equipmentId.isNotEmpty) {
          return '${AppRoutes.ownerEquiment}/$equipmentId';
        }
        return _isOwnerRole ? AppRoutes.ownerEquiment : AppRoutes.searchList;

      default:
        return notificationsHomeRoute();
    }
  }

  bool _isSafeBackendRoute(String route) {
    if (route.isEmpty) return false;
    if (!route.startsWith('/')) return false;

    // Avoid routing owners to client-only routes and vice versa.
    if (_isOwnerRole && route.startsWith('/owner/')) return true;
    if (!_isOwnerRole && !route.startsWith('/owner/')) return true;

    // allow notifications home regardless
    if (route == AppRoutes.notifications || route == AppRoutes.ownerNotifications) {
      return true;
    }

    return false;
  }

  Future<void> navigate(AppNotification notification) async {
    final router = ref.read(routerProvider);
    final route = resolveRoute(notification);

    final startup = ref.read(appStartupProvider).routeState;
    final session = ref.read(authProvider).session;

    final isReady = startup == AppStartupRouteState.client ||
        startup == AppStartupRouteState.owner;

    if (!isReady) {
      await savePendingRoute(route);

      if (session == null) {
        final from = Uri.encodeComponent(route);
        router.go('${AppRoutes.login}?from=$from');
      }

      return;
    }

    router.go(route);
  }

  Future<void> savePendingRoute(String route) async {
    await storage.savePendingRoute(route);
  }

  Future<void> flushPendingRouteIfAny() async {
    final route = await storage.readPendingRoute();
    if ((route ?? '').isEmpty) return;

    await storage.clearPendingRoute();
    ref.read(routerProvider).go(route!);
  }
}
