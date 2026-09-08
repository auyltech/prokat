import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/equipment/models/equipment_location.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/l10n/app_localizations.dart';

String locationCityLabel(
  WidgetRef ref,
  BuildContext context, {
  required String? city,
  LocalizedNames names = const LocalizedNames(),
}) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return catalogCityLabel(
    city: city,
    languageCode: languageCode,
    catalog: ref.watch(catalogProvider).valueOrNull,
    fallback: (_) => names.pickPreferRu(languageCode, fallback: city ?? ''),
  );
}

String formatLocationModel(
  WidgetRef ref,
  BuildContext context,
  LocationModel location,
) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return formatStreetCity(
    l10n: AppLocalizations.of(context)!,
    street: location.labelStreet(languageCode),
    houseNumber: location.houseNumber,
    city: locationCityLabel(
      ref,
      context,
      city: location.city,
      names: location.cityNames,
    ),
  );
}

String formatSearchResult(
  WidgetRef ref,
  BuildContext context,
  LocationSearchResult address,
) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return formatStreetCity(
    l10n: AppLocalizations.of(context)!,
    street: address.labelStreet(languageCode),
    houseNumber: address.houseNumber,
    city: locationCityLabel(
      ref,
      context,
      city: address.city,
      names: address.cityNames,
    ),
  );
}

String formatEquipmentLocation(
  WidgetRef ref,
  BuildContext context,
  EquipmentLocation location,
) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return formatStreetCity(
    l10n: AppLocalizations.of(context)!,
    street: location.labelStreet(languageCode),
    houseNumber: location.houseNumber,
    city: locationCityLabel(
      ref,
      context,
      city: location.city,
      names: location.cityNames,
    ),
  );
}
