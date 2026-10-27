import 'package:flutter/widgets.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/tariff_unit_labels.dart';
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
/// older rows that still contain `/PER_HOUR` etc. Uses full phrases (no slash).
String localizePriceRateInNotificationText(
  String text,
  AppLocalizations l10n, {
  CatalogBundle? catalog,
}) {
  if (text.isEmpty) return text;
  final languageCode = normalizeTariffLanguageCode(l10n.localeName);
  return text.replaceAllMapped(
    RegExp(r'/?\s*(PER_[A-Z0-9_]+)\b', caseSensitive: false),
    (match) {
      final code = (match.group(1) ?? '').toUpperCase();
      final label = resolveTariffUnitLabel(
        code: code,
        languageCode: languageCode,
        catalog: catalog,
        legacyLookup: legacyTariffUnitLookupFromL10n(l10n),
      );
      return label.isEmpty ? code : ' $label';
    },
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
