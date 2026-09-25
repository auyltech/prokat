import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/l10n/app_localizations.dart';

PriceEntry? firstSharePrice(Equipment equipment) {
  for (final entry in equipment.prices) {
    if (entry.price > 0) return entry;
  }
  return null;
}

String? shareDescriptionOf(Equipment equipment) {
  final description = shortDescriptionOf(equipment);
  if (description.isEmpty) return null;
  return description;
}

String? sharePriceLine(Equipment equipment, AppLocalizations l10n) {
  final entry = firstSharePrice(equipment);
  if (entry == null) return null;
  return TariffDraft.fromEntry(entry).collapsedSubtitle(l10n);
}

String equipmentShareMessage(
  AppLocalizations l10n, {
  required String name,
  required String priceLine,
  required String url,
}) {
  return l10n.shareEquipmentMessage(name, priceLine, url);
}
