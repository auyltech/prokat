import 'package:prokat/features/user_safety/user_safety_error_message.dart';
import 'package:prokat/l10n/app_localizations.dart';

String requestCreateErrorMessage({
  required AppLocalizations l10n,
  String? errorCode,
  String? fallback,
}) {
  switch (errorCode) {
    case contentNotAllowedErrorCode:
      return l10n.contentNotAllowed;
    default:
      final trimmed = fallback?.trim() ?? '';
      return trimmed.isEmpty ? l10n.somethingWentWrongTryAgain : trimmed;
  }
}
