import 'package:prokat/features/auth/providers/auth_state.dart';
import 'package:prokat/l10n/app_localizations.dart';

String otpRequestErrorMessage(AuthState state, AppLocalizations l10n) {
  switch (state.errorCode) {
    case 'RATE_LIMITED':
      return state.error ?? l10n.failedSendOtp;
    case 'APP_NOT_VERIFIED':
    case 'INSTALLATION_BLOCKED':
      return state.error ?? l10n.somethingWentWrong;
    default:
      return state.error ?? l10n.failedSendOtp;
  }
}
