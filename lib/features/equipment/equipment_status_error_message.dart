import 'package:prokat/l10n/app_localizations.dart';

const equipmentStatusPhotoRequiredCode = 'CONFLICT:EQUIPMENT:STATUS:PHOTO';

String equipmentStatusErrorMessage({
  required AppLocalizations l10n,
  String? errorCode,
  String? fallback,
}) {
  switch (errorCode) {
    case equipmentStatusPhotoRequiredCode:
      return l10n.equipmentSubmitPhotoRequired;
    default:
      final trimmed = fallback?.trim() ?? '';
      return trimmed.isEmpty ? l10n.failedToSubmit : trimmed;
  }
}
