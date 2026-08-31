import 'package:prokat/l10n/app_localizations.dart';

bool isSameCity(String? a, String? b) {
  return (a?.trim().toLowerCase() ?? '') == (b?.trim().toLowerCase() ?? '');
}

String? canonicalCity(String? city, Iterable<String> knownCities) {
  if (city == null || city.trim().isEmpty) return null;

  for (final known in knownCities) {
    if (isSameCity(known, city)) return known;
  }

  return null;
}

String localizedCityName(String? city, AppLocalizations l10n) {
  return city?.trim() ?? '';
}

String formatStreetCity({
  required AppLocalizations l10n,
  String? street,
  String? houseNumber,
  String? city,
}) {
  return [
    [
      street?.trim() ?? '',
      houseNumber?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(', '),
    localizedCityName(city, l10n),
  ].where((part) => part.isNotEmpty).join(', ');
}

String formatCityCountry({
  required AppLocalizations l10n,
  String? city,
  String? country,
}) {
  return [
    localizedCityName(city, l10n),
    country?.trim() ?? '',
  ].where((part) => part.isNotEmpty).join(', ');
}
