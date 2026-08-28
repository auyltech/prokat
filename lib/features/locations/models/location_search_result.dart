import 'package:prokat/features/catalog/models/localized_names.dart';

class LocationSearchResult {
  final String name;
  final String street;
  final LocalizedNames streetNames;
  final String? houseNumber;
  final String? city;
  final LocalizedNames cityNames;
  final String? country;
  final LocalizedNames countryNames;
  final String? region;
  final LocalizedNames regionNames;
  final double longitude;
  final double latitude;

  LocationSearchResult({
    required this.name,
    required this.street,
    this.streetNames = const LocalizedNames(),
    this.houseNumber,
    this.city,
    this.cityNames = const LocalizedNames(),
    this.country,
    this.countryNames = const LocalizedNames(),
    this.region,
    this.regionNames = const LocalizedNames(),
    required this.longitude,
    required this.latitude,
  });

  String labelStreet(String languageCode) =>
      streetNames.pickPreferRu(languageCode, fallback: street);

  String labelCity(String languageCode) =>
      cityNames.pickPreferRu(languageCode, fallback: city ?? '');

  String labelCountry(String languageCode) =>
      countryNames.pickPreferRu(languageCode, fallback: country ?? '');

  String streetLine(String languageCode) {
    return [
      labelStreet(languageCode),
      houseNumber?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(', ');
  }

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    final house = json['houseNumber']?.toString().trim();

    return LocationSearchResult(
      name: json['name']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      streetNames: LocalizedNames.fromJson(json['streetNames']),
      houseNumber: (house == null || house.isEmpty) ? null : house,
      city: json['city']?.toString(),
      cityNames: LocalizedNames.fromJson(json['cityNames']),
      country: json['country']?.toString(),
      countryNames: LocalizedNames.fromJson(json['countryNames']),
      region: json['region']?.toString(),
      regionNames: LocalizedNames.fromJson(json['regionNames']),
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }
}
