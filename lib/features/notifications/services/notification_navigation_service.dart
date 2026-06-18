import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';

// TODO: fix route reslove
// Backend should send event, type, targetId,
// Flutter app should build route
// Save notification event and targetId, not route, remove current save route
class NotificationNavigationService {
  final Ref ref;
  final NotificationLocalStorage storage;

  NotificationNavigationService(this.ref, this.storage);

  bool get _isOwnerRole =>
      ref.read(authProvider).session?.user?.isOwner ?? false;

  String notificationsHomeRoute() {
    return _isOwnerRole
        ? AppRoutes.ownerNotifications
        : AppRoutes.clientNotifications;
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
          return _isOwnerRole
              ? '${AppRoutes.ownerChatList}/$chatId'
              : '${AppRoutes.clientChatList}/$chatId';
        }
        return notificationsHomeRoute();

      case 'BOOKING_CREATED':
      case 'BOOKING_ACCEPTED':
      case 'BOOKING_REJECTED':
      case 'WORK_STATUS_UPDATED':
      case 'WORK_COMPLETED':
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

    if (_isOwnerRole) {
      return route.startsWith(AppRoutes.ownerMain);
    }

    return route.startsWith(AppRoutes.clientMain);
  }

  Future<void> navigate(AppNotification notification) async {
    final router = ref.read(routerProvider);
    final route = resolveRoute(notification);

    if (!_isSafeBackendRoute(route)) {
      return;
    }

    final startup = ref.read(appStartupProvider).routeState;
    final session = ref.read(authProvider).session;

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

    router.go(route);
  }

  Future<void> savePendingRoute(String route) async {
    await storage.savePendingRoute(route);
  }

  Future<void> flushPendingRouteIfAny() async {
    final route = await storage.readPendingRoute();

    if ((route ?? '').isEmpty) return;

    await storage.clearPendingRoute();

    if (_isSafeBackendRoute(route!)) {
      ref.read(routerProvider).go(route);
    } else {
      ref.read(routerProvider).go(notificationsHomeRoute());
    }
  }
}
