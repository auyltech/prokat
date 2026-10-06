import 'package:prokat/l10n/app_localizations.dart';

const userBlockedErrorCode = 'USER_BLOCKED';
const contentNotAllowedErrorCode = 'CONTENT_NOT_ALLOWED';

String userSafetyErrorMessage(AppLocalizations l10n, String? code) {
  if (code == userBlockedErrorCode) return l10n.interactionUnavailableBody;
  if (code == contentNotAllowedErrorCode) return l10n.contentNotAllowed;
  return l10n.somethingWentWrongTryAgain;
}
