import 'package:prokat/l10n/app_localizations.dart';

const bookingActiveLimitCode = 'BOOKING_ACTIVE_LIMIT';

String bookingCreateErrorMessage({
  required AppLocalizations l10n,
  String? errorCode,
  String? fallback,
}) {
  switch (errorCode) {
    case bookingActiveLimitCode:
      return l10n.bookingActiveLimitReached;
    default:
      final trimmed = fallback?.trim() ?? '';
      return trimmed.isEmpty ? l10n.somethingWentWrongTryAgain : trimmed;
  }
}
