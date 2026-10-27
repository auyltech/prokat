import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Optional legacy ARB lookup for the four historic tariff codes.
///
/// Used only when the unit is missing from [CatalogBundle.tariffUnits].
typedef TariffUnitLegacyLookup = String? Function(
  String code,
  String languageCode,
);

const legacyTariffUnitCodes = <String>{
  'PER_HOUR',
  'PER_DAY',
  'PER_TRIP',
  'PER_CUBIC_METER',
};

/// Normalizes `kk-KZ` / `en_US` / `ru` to a catalog language code.
String normalizeTariffLanguageCode(String? locale) {
  if (locale == null) return 'ru';
  final trimmed = locale.trim();
  if (trimmed.isEmpty) return 'ru';
  final base = trimmed.toLowerCase().split(RegExp(r'[-_]')).first;
  if (base == 'kk' || base == 'en' || base == 'ru') return base;
  return 'ru';
}

String _nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed;
}

/// Builds a legacy lookup from generated [AppLocalizations] (`ratePer*` keys —
/// full phrases without slash suffixes).
TariffUnitLegacyLookup legacyTariffUnitLookupFromL10n(AppLocalizations l10n) {
  return (code, _) {
    return switch (code) {
      'PER_HOUR' => l10n.ratePerHour,
      'PER_DAY' => l10n.ratePerDay,
      'PER_TRIP' => l10n.ratePerTrip,
      'PER_CUBIC_METER' => l10n.ratePerCubicMeter,
      _ => null,
    };
  };
}

/// Resolves a localized tariff-unit label.
///
/// Priority:
/// 1. Catalog unit → current locale (non-empty)
/// 2. Same unit → Russian (non-empty)
/// 3. Same unit → any remaining non-empty locale, else the unit [code]
/// 4. Unit absent → legacy ARB for the four historic codes
/// 5. Otherwise → raw [code] (never remapped to another unit)
String resolveTariffUnitLabel({
  required String? code,
  required String languageCode,
  CatalogBundle? catalog,
  TariffUnitLegacyLookup? legacyLookup,
}) {
  final normalized = (code ?? '').trim();
  if (normalized.isEmpty) return '';

  final locale = normalizeTariffLanguageCode(languageCode);
  final unit = catalog?.tariffUnitByCode(normalized);

  if (unit != null) {
    final fromNames = unit.names.pickPreferRu(locale, fallback: '');
    if (fromNames.isNotEmpty) return fromNames;
    return normalized;
  }

  final legacy = _nonEmpty(legacyLookup?.call(normalized, locale));
  if (legacy.isNotEmpty && legacyTariffUnitCodes.contains(normalized)) {
    return legacy;
  }

  return normalized;
}

/// Formats `15 000 ₸ за час` (no slash before the unit label).
String formatPriceWithTariffUnit({
  required dynamic price,
  required String unitLabel,
}) {
  final amount = formatPriceNumber(price);
  final unit = unitLabel.trim();
  if (unit.isEmpty) return '$amount ₸';
  return '$amount ₸ $unit';
}

String formatPriceWithTariffUnitCode({
  required dynamic price,
  required String? code,
  required String languageCode,
  CatalogBundle? catalog,
  TariffUnitLegacyLookup? legacyLookup,
}) {
  return formatPriceWithTariffUnit(
    price: price,
    unitLabel: resolveTariffUnitLabel(
      code: code,
      languageCode: languageCode,
      catalog: catalog,
      legacyLookup: legacyLookup,
    ),
  );
}

/// Resolves a unit label for equipment/catalog cards (catalog + optional ARB).
String tariffUnitLabelForUi({
  required String? code,
  required String languageCode,
  CatalogBundle? catalog,
  AppLocalizations? l10n,
}) {
  return resolveTariffUnitLabel(
    code: code,
    languageCode: languageCode,
    catalog: catalog,
    legacyLookup: l10n == null ? null : legacyTariffUnitLookupFromL10n(l10n),
  );
}

/// Formats card price line using [formatPriceWithTariffUnitCode].
String formatEquipmentPriceLine({
  required dynamic price,
  required String? code,
  required String languageCode,
  CatalogBundle? catalog,
  AppLocalizations? l10n,
}) {
  return formatPriceWithTariffUnitCode(
    price: price,
    code: code,
    languageCode: languageCode,
    catalog: catalog,
    legacyLookup: l10n == null ? null : legacyTariffUnitLookupFromL10n(l10n),
  );
}

/// Active catalog units as selectable options (`value` = code).
///
/// When [CatalogBundle.tariffUnits] is `null` (legacy payload), falls back to
/// the four historic codes. An explicit empty list yields no dynamic options
/// (unless [includeCode] forces a historical value into the list).
List<PriceRateOption> buildTariffUnitSelectOptions({
  CatalogBundle? catalog,
  required String languageCode,
  TariffUnitLegacyLookup? legacyLookup,
  String? includeCode,
}) {
  final locale = normalizeTariffLanguageCode(languageCode);
  final include = includeCode?.trim();
  final options = <PriceRateOption>[];
  final seen = <String>{};

  void addCode(String code) {
    if (code.isEmpty || seen.contains(code)) return;
    seen.add(code);
    options.add(
      PriceRateOption(
        value: code,
        label: resolveTariffUnitLabel(
          code: code,
          languageCode: locale,
          catalog: catalog,
          legacyLookup: legacyLookup,
        ),
      ),
    );
  }

  final tariffUnits = catalog?.tariffUnits;
  if (tariffUnits == null) {
    for (final option in priceRateOptions) {
      addCode(option.value);
    }
  } else {
    final active = [...catalog!.activeTariffUnits]
      ..sort((a, b) {
        final bySort = a.sortIndex.compareTo(b.sortIndex);
        if (bySort != 0) return bySort;
        return a.code.compareTo(b.code);
      });
    for (final unit in active) {
      addCode(unit.code);
    }
  }

  if (include != null && include.isNotEmpty) {
    addCode(include);
  }

  return options;
}
