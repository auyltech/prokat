import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

const vacuumTariffSeptic = 'septic_sewage';
const vacuumTariffWater = 'water_pumping';
const vacuumTariffCesspit = 'cesspit_pumping';
const vacuumTariffSewerCleaning = 'sewer_cleaning';
const vacuumTariffLiquidWaste = 'liquid_waste';
const vacuumTariffOther = 'other';

const vacuumPresetTariffKeys = [vacuumTariffSeptic, vacuumTariffWater];

const vacuumServiceTypeKeys = [
  vacuumTariffSeptic,
  vacuumTariffWater,
  vacuumTariffCesspit,
  vacuumTariffSewerCleaning,
  vacuumTariffLiquidWaste,
  vacuumTariffOther,
];

bool equipmentIsVacuum(Equipment equipment, {String? vacuumCategoryId}) {
  if (equipment.category?.slug == vacuumTrucksSlug) return true;
  if (vacuumCategoryId != null &&
      vacuumCategoryId.isNotEmpty &&
      equipment.categoryId == vacuumCategoryId) {
    return true;
  }
  return false;
}

String tariffServiceTitle(
  String key,
  String customName,
  AppLocalizations l10n,
) {
  return switch (key) {
    vacuumTariffSeptic => l10n.tariffSepticSewage,
    vacuumTariffWater => l10n.tariffWaterPumping,
    vacuumTariffCesspit => l10n.tariffCesspitPumping,
    vacuumTariffSewerCleaning => l10n.tariffSewerCleaning,
    vacuumTariffLiquidWaste => l10n.tariffLiquidWaste,
    vacuumTariffOther =>
      customName.trim().isEmpty ? l10n.serviceOther : customName.trim(),
    _ => customName.trim().isNotEmpty ? customName.trim() : key,
  };
}

String tariffServiceOptionLabel(String key, AppLocalizations l10n) {
  return switch (key) {
    vacuumTariffSeptic => l10n.tariffSepticSewage,
    vacuumTariffWater => l10n.tariffWaterPumping,
    vacuumTariffCesspit => l10n.tariffCesspitPumping,
    vacuumTariffSewerCleaning => l10n.tariffSewerCleaning,
    vacuumTariffLiquidWaste => l10n.tariffLiquidWaste,
    vacuumTariffOther => l10n.serviceOther,
    _ => key,
  };
}

bool isKnownTariffKey(String? label) {
  if (label == null || label.isEmpty) return false;
  return vacuumServiceTypeKeys.contains(label) && label != vacuumTariffOther;
}

String persistTariffLabel({
  required String labelKey,
  required String customName,
}) {
  if (labelKey == vacuumTariffOther) return customName.trim();
  if (isKnownTariffKey(labelKey)) return labelKey;
  return customName.trim().isNotEmpty ? customName.trim() : labelKey;
}

class TariffDraft {
  final String? id;
  final String labelKey;
  final String customName;
  final int? price;
  final PriceRateOption priceRate;
  final bool isStartingFrom;
  final bool expanded;
  final bool isPreset;

  TariffDraft({
    this.id,
    required this.labelKey,
    this.customName = '',
    this.price,
    PriceRateOption? priceRate,
    this.isStartingFrom = false,
    this.expanded = false,
    this.isPreset = false,
  }) : priceRate = priceRate ?? priceRateOptions.first;

  factory TariffDraft.preset(String labelKey) {
    return TariffDraft(
      labelKey: labelKey,
      priceRate: priceRateOptions.first,
      isPreset: true,
    );
  }

  factory TariffDraft.fromEntry(PriceEntry entry) {
    final raw = (entry.label ?? '').trim();
    final known = isKnownTariffKey(raw);
    return TariffDraft(
      id: entry.id,
      labelKey: known
          ? raw
          : (raw.isEmpty ? vacuumTariffOther : vacuumTariffOther),
      customName: known ? '' : raw,
      price: entry.price > 0 ? entry.price : null,
      priceRate: entry.priceRate,
      isStartingFrom: entry.isStartingFrom,
      isPreset: vacuumPresetTariffKeys.contains(raw),
    );
  }

  factory TariffDraft.custom() {
    return TariffDraft(
      labelKey: '',
      priceRate: priceRateOptions.first,
      expanded: true,
    );
  }

  bool get hasPrice => (price ?? 0) > 0;

  bool get isSavable {
    if (!hasPrice) return false;
    if (isPreset) return true;
    if (labelKey.isEmpty) return false;
    if (labelKey == vacuumTariffOther) return customName.trim().isNotEmpty;
    return true;
  }

  String persistedLabel() {
    return persistTariffLabel(labelKey: labelKey, customName: customName);
  }

  String title(AppLocalizations l10n) {
    if (isPreset || isKnownTariffKey(labelKey)) {
      return tariffServiceTitle(labelKey, customName, l10n);
    }
    if (customName.trim().isNotEmpty) return customName.trim();
    if (labelKey.isNotEmpty && labelKey != vacuumTariffOther) {
      return labelKey;
    }
    return l10n.newRate;
  }

  String collapsedSubtitle(AppLocalizations l10n) {
    if (!hasPrice) return l10n.priceNotSpecified;
    final unit = rateUnitLabel(priceRate, l10n);
    final amount = formatPriceNumber(price!);
    if (isStartingFrom) {
      return '${l10n.priceFromPrefix} $amount ₸ / $unit';
    }
    return '$amount ₸ / $unit';
  }

  String fingerprint() {
    return [
      id ?? '',
      persistedLabel(),
      '${price ?? 0}',
      priceRate.value,
      isStartingFrom ? '1' : '0',
    ].join('|');
  }

  TariffDraft copyWith({
    String? id,
    String? labelKey,
    String? customName,
    int? price,
    bool clearPrice = false,
    PriceRateOption? priceRate,
    bool? isStartingFrom,
    bool? expanded,
    bool? isPreset,
  }) {
    return TariffDraft(
      id: id ?? this.id,
      labelKey: labelKey ?? this.labelKey,
      customName: customName ?? this.customName,
      price: clearPrice ? null : (price ?? this.price),
      priceRate: priceRate ?? this.priceRate,
      isStartingFrom: isStartingFrom ?? this.isStartingFrom,
      expanded: expanded ?? this.expanded,
      isPreset: isPreset ?? this.isPreset,
    );
  }
}

List<TariffDraft> tariffsForEditor(
  Equipment equipment, {
  String? vacuumCategoryId,
}) {
  final existing = equipment.prices.map(TariffDraft.fromEntry).toList();
  if (!equipmentIsVacuum(equipment, vacuumCategoryId: vacuumCategoryId)) {
    return existing;
  }

  final result = [...existing];
  for (final key in vacuumPresetTariffKeys) {
    if (!result.any((item) => item.labelKey == key && item.isPreset)) {
      result.add(TariffDraft.preset(key));
    }
  }

  result.sort((a, b) {
    final ai = vacuumPresetTariffKeys.indexOf(a.labelKey);
    final bi = vacuumPresetTariffKeys.indexOf(b.labelKey);
    final aOrder = a.isPreset && ai >= 0 ? ai : 100;
    final bOrder = b.isPreset && bi >= 0 ? bi : 100;
    if (aOrder != bOrder) return aOrder.compareTo(bOrder);
    return (a.id ?? a.labelKey).compareTo(b.id ?? b.labelKey);
  });
  return result;
}

String shortDescriptionOf(Equipment equipment) {
  final rent = (equipment.rentCondition ?? '').trim();
  if (rent.isNotEmpty) return rent;
  return (equipment.ownerComment ?? '').trim();
}
