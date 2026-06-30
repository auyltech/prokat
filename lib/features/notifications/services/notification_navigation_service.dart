import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
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
    switch (notification.type) {
      // ===========================
      // Requests
      // ===========================

      case NotificationType.requestCreated:
      case NotificationType.requestCancelled:
      case NotificationType.requestExpired:
        return _isOwnerRole
            ? AppRoutes.ownerRequests
            : AppRoutes.clientRequests;

      // ===========================
      // Offers / Negotiation
      // ===========================

      case NotificationType.offerCreated:
      case NotificationType.offerCancelled:
      case NotificationType.offerAccepted:
      case NotificationType.offerRejected:
      case NotificationType.offerExpired:
      case NotificationType.counterOfferCreated:
      case NotificationType.counterOfferAccepted:
      case NotificationType.counterOfferRejected:
      case NotificationType.negotiationExpired:
      case NotificationType.negotiationClosed:
        return _isOwnerRole
            ? AppRoutes.ownerRequests
            : AppRoutes.clientRequests;

      // ===========================
      // Bookings
      // ===========================

      case NotificationType.bookingCreated:
      case NotificationType.bookingAccepted:
      case NotificationType.bookingRejected:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCancelled:
      case NotificationType.bookingCompleted:
      case NotificationType.clientConfirmedCompletion:
      case NotificationType.clientConfirmationRequired:
      case NotificationType.workOnTheWay:
      case NotificationType.workOnSite:
      case NotificationType.workStarted:
      case NotificationType.workPaused:
      case NotificationType.workFailed:
      case NotificationType.workCompleted:
        return _isOwnerRole ? AppRoutes.ownerBookings : AppRoutes.clientOrders;

      // ===========================
      // Chats
      // ===========================

      case NotificationType.chatMessageCreated:
      case NotificationType.bookingEventMessageCreated:
      case NotificationType.priceNegotiationMessageCreated:
      case NotificationType.adminMessageCreated:
        final chatId = notification.data["chatId"] as String?;

        if (chatId != null && chatId.isNotEmpty) {
          return _isOwnerRole
              ? '${AppRoutes.ownerChatList}/$chatId'
              : '${AppRoutes.clientChatList}/$chatId';
        }

        return notificationsHomeRoute();

      // ===========================
      // Reviews
      // ===========================

      case NotificationType.reviewAvailable:
      case NotificationType.reviewSubmitted:
      case NotificationType.reviewReminder:
        return _isOwnerRole ? AppRoutes.ownerBookings : AppRoutes.clientOrders;

      // ===========================
      // Equipment
      // ===========================

      case NotificationType.equipmentApproved:
      case NotificationType.equipmentRejected:
      case NotificationType.equipmentSuspended:
        final equipmentId = notification.data["equipmentId"] as String?;

        if (_isOwnerRole && equipmentId != null && equipmentId.isNotEmpty) {
          return '${AppRoutes.ownerEquiment}/$equipmentId';
        }

        return _isOwnerRole ? AppRoutes.ownerEquiment : AppRoutes.searchList;

      // ===========================
      // Owner Registration
      // ===========================

      case NotificationType.ownerProfileSubmitted:
      case NotificationType.ownerApproved:
      case NotificationType.ownerRejected:
      case NotificationType.documentRequired:
      case NotificationType.adminWarning:
        return _isOwnerRole
            ? AppRoutes.ownerRegistration
            : AppRoutes.becomeOwner;

      // ===========================
      // Billing
      // ===========================

      case NotificationType.balanceToppedUp:
      case NotificationType.lowBalanceWarning:
      case NotificationType.equipmentOfflineInsufficientBalance:
      case NotificationType.paymentFailed:
      case NotificationType.minutesPackageUsed:
        return AppRoutes.ownerPayment;

      // ===========================
      // Generic
      // ===========================

      case NotificationType.systemNotice:
        return notificationsHomeRoute();
    }
  }

  Future<void> navigate(AppNotification notification) async {
    final router = ref.read(routerProvider);
    final route = resolveRoute(notification);

    final startup = ref.read(appStartupProvider).routeState;
    final session = ref.read(authProvider).session;

    if (notification.category == "BOOKING") {
      ref
          .read(bookingProvider.notifier)
          .invalidate(
            mode: startup == AppStartupRouteState.owner
                ? AppMode.ownerMode
                : AppMode.clientMode,
          );
    } else if (notification.category == "REQUEST") {
      ref
          .read(bookingProvider.notifier)
          .invalidate(
            mode: startup == AppStartupRouteState.owner
                ? AppMode.ownerMode
                : AppMode.clientMode,
          );
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

    router.go(route);
  }

  Future<void> savePendingRoute(String route) async {
    await storage.savePendingRoute(route);
  }

  Future<void> flushPendingRouteIfAny() async {
    final route = await storage.readPendingRoute();

    if ((route ?? '').isEmpty) return;

    await storage.clearPendingRoute();

    // if (_isSafeBackendRoute(route!)) {
    //   ref.read(routerProvider).go(route);
    // } else {
    //   ref.read(routerProvider).go(notificationsHomeRoute());
    // }
  }
}
