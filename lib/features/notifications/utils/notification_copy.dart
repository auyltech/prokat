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

/// Replaces raw backend PriceRate enums left in already-rendered copy.
///
/// New notifications should get localized fragments from the API; this covers
/// older rows that still contain `/PER_HOUR` etc.
String localizePriceRateInNotificationText(String text, AppLocalizations l10n) {
  if (text.isEmpty) return text;
  return text
      .replaceAll(
        RegExp(r'/?\s*PER_HOUR\b', caseSensitive: false),
        l10n.perHour,
      )
      .replaceAll(
        RegExp(r'/?\s*PER_TRIP\b', caseSensitive: false),
        l10n.perTrip,
      )
      .replaceAll(RegExp(r'/?\s*PER_DAY\b', caseSensitive: false), l10n.perDay)
      .replaceAll(
        RegExp(r'/?\s*PER_CUBIC_METER\b', caseSensitive: false),
        l10n.perM3,
      );
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
