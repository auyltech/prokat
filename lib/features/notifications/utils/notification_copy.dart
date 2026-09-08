import 'package:flutter/widgets.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/l10n/app_localizations.dart';

AppLocalizations notificationL10n(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'en':
      return lookupAppLocalizations(const Locale('en'));
    case 'kk':
      return lookupAppLocalizations(const Locale('kk'));
    default:
      return lookupAppLocalizations(const Locale('ru'));
  }
}

String? fallbackNotificationTitle(NotificationType type, String languageCode) {
  final l10n = notificationL10n(languageCode);
  return switch (type) {
    NotificationType.ownerApproved => l10n.notificationOwnerApprovedTitle,
    NotificationType.ownerRejected => l10n.notificationOwnerRejectedTitle,
    NotificationType.bookingCompleted => l10n.notificationBookingCompletedTitle,
    _ => null,
  };
}

String? fallbackNotificationBody(NotificationType type, String languageCode) {
  final l10n = notificationL10n(languageCode);
  return switch (type) {
    NotificationType.ownerApproved => l10n.notificationOwnerApprovedBody,
    NotificationType.ownerRejected => l10n.notificationOwnerRejectedBody,
    NotificationType.bookingCompleted => l10n.notificationBookingCompletedBody,
    _ => null,
  };
}
