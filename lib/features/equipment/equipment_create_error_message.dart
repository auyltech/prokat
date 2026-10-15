import 'package:prokat/l10n/app_localizations.dart';

const equipmentCreateLimitCode = 'MAX_LIMIT:EQUIPMENT:CREATE';

String equipmentCreateErrorMessage({
  required AppLocalizations l10n,
  String? errorCode,
  dynamic details,
  String? selectedGroup,
}) {
  if (errorCode != equipmentCreateLimitCode) return l10n.couldNotAddEquipment;
  final maximum = details is Map ? details['maximum'] : null;
  final group = details is Map
      ? details['catalogGroup'] ?? selectedGroup
      : selectedGroup;
  if (maximum is! num ||
      !maximum.isFinite ||
      maximum < 0 ||
      maximum != maximum.truncateToDouble()) {
    return l10n.couldNotAddEquipment;
  }
  if (group == 'EQUIPMENT') return l10n.equipmentQuotaReached(maximum.toInt());
  if (group == 'MACHINERY') return l10n.machineryQuotaReached(maximum.toInt());
  return l10n.couldNotAddEquipment;
}
