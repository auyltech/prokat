import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';

/// Builds the in-app destination for a notification tap.
///
/// Uses [opensOwner] / [notificationsHome] from the caller so shell selection
/// stays outside this pure mapping (audience + mode are resolved separately).
String resolveNotificationRoute({
  required AppNotification notification,
  required bool opensOwner,
  required String notificationsHome,
}) {
  String bookingsOrOrders() =>
      opensOwner ? AppRoutes.ownerBookings : AppRoutes.clientOrders;

  String chatList() =>
      opensOwner ? AppRoutes.ownerChatList : AppRoutes.clientChatList;

  String? chatOrNull() {
    final chatId = notification.chatId;
    if (chatId == null) return null;
    return opensOwner
        ? '${AppRoutes.ownerChatList}/direct/$chatId'
        : '${AppRoutes.clientChatList}/direct/$chatId';
  }

  String chatOrFallback(String fallback) => chatOrNull() ?? fallback;

  switch (notification.type) {
    // ===========================
    // Requests
    // ===========================

    case NotificationType.requestCreated:
    case NotificationType.requestCancelled:
    case NotificationType.requestExpired:
      return opensOwner ? AppRoutes.ownerRequests : AppRoutes.clientRequests;

    // ===========================
    // Offers / Negotiation
    // ===========================

    case NotificationType.offerCreated:
    case NotificationType.offerCancelled:
    case NotificationType.offerExpired:
      return AppRoutes.clientRequests;

    case NotificationType.offerAccepted:
    case NotificationType.offerRejected:
    case NotificationType.offerNotSelected:
      return AppRoutes.ownerRequests;

    case NotificationType.counterOfferCreated:
    case NotificationType.counterOfferAccepted:
    case NotificationType.counterOfferRejected:
    case NotificationType.negotiationExpired:
    case NotificationType.negotiationClosed:
      return chatOrFallback(chatList());

    // ===========================
    // Bookings
    // ===========================

    case NotificationType.bookingCreated:
    case NotificationType.bookingAccepted:
    case NotificationType.bookingRejected:
    case NotificationType.bookingCancelled:
    case NotificationType.bookingCompleted:
    case NotificationType.clientConfirmedCompletion:
      return bookingsOrOrders();

    case NotificationType.bookingConfirmed:
    case NotificationType.bookingWorkStatus:
    case NotificationType.clientConfirmationRequired:
    case NotificationType.workOnTheWay:
    case NotificationType.workOnSite:
    case NotificationType.workStarted:
    case NotificationType.workPaused:
    case NotificationType.workFailed:
    case NotificationType.workCompleted:
      return chatOrFallback(bookingsOrOrders());

    // ===========================
    // Chats
    // ===========================

    case NotificationType.chatMessageCreated:
    case NotificationType.bookingEventMessageCreated:
    case NotificationType.priceNegotiationMessageCreated:
    case NotificationType.adminMessageCreated:
      return chatOrFallback(notificationsHome);

    // ===========================
    // Reviews
    // ===========================

    case NotificationType.reviewAvailable:
    case NotificationType.reviewSubmitted:
    case NotificationType.reviewReminder:
      return bookingsOrOrders();

    // ===========================
    // Equipment
    // ===========================

    case NotificationType.equipmentApproved:
    case NotificationType.equipmentRejected:
    case NotificationType.equipmentSuspended:
      final equipmentId = notification.equipmentId;

      if (opensOwner && equipmentId != null) {
        return '${AppRoutes.ownerEquipment}/$equipmentId';
      }

      return opensOwner ? AppRoutes.ownerEquipment : AppRoutes.searchList;

    // ===========================
    // Owner Registration
    // ===========================

    case NotificationType.ownerApproved:
      return AppRoutes.ownerProfile;

    case NotificationType.ownerRejected:
      return AppRoutes.becomeOwner;

    case NotificationType.ownerProfileSubmitted:
    case NotificationType.documentRequired:
    case NotificationType.adminWarning:
      return opensOwner ? AppRoutes.ownerRegistration : AppRoutes.becomeOwner;

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
      return notificationsHome;
  }
}

bool isTrustedNotificationAppRoute(String route) {
  return route.startsWith(AppRoutes.clientMain) ||
      route.startsWith(AppRoutes.ownerMain);
}
