import 'package:prokat/l10n/app_localizations.dart';

const offerCreateRequestNotFoundCode = 'NOT_FOUND:OFFERS:CREATE';
const offerCreateZeroBalanceCode = 'CONFLICT:OFFERS:CREATE:BALANCE';

String offerCreateErrorMessage({
  required AppLocalizations l10n,
  String? errorCode,
  String? fallback,
}) {
  switch (errorCode) {
    case offerCreateRequestNotFoundCode:
      return l10n.offerCreateRequestNotFound;
    case offerCreateZeroBalanceCode:
      return l10n.cannotRespondWithZeroBalance;
    default:
      final trimmed = fallback?.trim() ?? '';
      return trimmed.isEmpty ? l10n.somethingWentWrong : trimmed;
  }
}
