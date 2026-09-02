import 'package:prokat/features/notifications/models/notification_type.dart';

enum NotificationAudience { client, owner }

NotificationAudience? notificationAudienceFromData(Map<String, dynamic> data) {
  final raw = data['audience']?.toString().trim().toUpperCase();
  if (raw == 'OWNER') return NotificationAudience.owner;
  if (raw == 'CLIENT') return NotificationAudience.client;
  return null;
}

/// Whether tapping this notification should open the owner shell.
///
/// Account role (`user.isOwner`) is the wrong signal: dual-role users are
/// always owners. Prefer payload audience, then one-sided event types, then
/// the current app mode.
bool notificationOpensOwnerShell({
  required NotificationType type,
  required Map<String, dynamic> data,
  required bool isOwnerMode,
}) {
  switch (notificationAudienceFromData(data)) {
    case NotificationAudience.owner:
      return true;
    case NotificationAudience.client:
      return false;
    case null:
      break;
  }

  switch (type) {
    case NotificationType.workOnTheWay:
    case NotificationType.workOnSite:
    case NotificationType.workStarted:
    case NotificationType.workPaused:
    case NotificationType.workFailed:
    case NotificationType.workCompleted:
    case NotificationType.clientConfirmationRequired:
    case NotificationType.bookingWorkStatus:
    case NotificationType.offerCreated:
    case NotificationType.offerCancelled:
    case NotificationType.offerExpired:
      return false;

    case NotificationType.bookingCreated:
    case NotificationType.offerAccepted:
    case NotificationType.offerRejected:
    case NotificationType.offerNotSelected:
    case NotificationType.requestCreated:
    case NotificationType.equipmentApproved:
    case NotificationType.equipmentRejected:
    case NotificationType.equipmentSuspended:
    case NotificationType.ownerProfileSubmitted:
    case NotificationType.ownerApproved:
    case NotificationType.ownerRejected:
    case NotificationType.documentRequired:
    case NotificationType.adminWarning:
    case NotificationType.balanceToppedUp:
    case NotificationType.lowBalanceWarning:
    case NotificationType.equipmentOfflineInsufficientBalance:
    case NotificationType.paymentFailed:
    case NotificationType.minutesPackageUsed:
      return true;

    default:
      return isOwnerMode;
  }
}
