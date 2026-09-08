import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';

class LocationModel {
  final String? id;
  final String service; // "EQUIPMENT" | "ADDRESS"

  final String street;
  final LocalizedNames streetNames;
  final String? houseNumber;
  final String city;
  final LocalizedNames cityNames;
  final String country;
  final LocalizedNames countryNames;
  final String? region;
  final LocalizedNames regionNames;

  final String? comment;
  final String? instructions;

  final double longitude;
  final double latitude;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? userId;
  final String? equipmentId;

  LocationModel({
    this.id,
    required this.service,
    required this.street,
    this.streetNames = const LocalizedNames(),
    this.houseNumber,
    required this.city,
    this.cityNames = const LocalizedNames(),
    required this.country,
    this.countryNames = const LocalizedNames(),
    this.region,
    this.regionNames = const LocalizedNames(),
    required this.longitude,
    required this.latitude,
    this.createdAt,
    this.updatedAt,
    this.comment,
    this.instructions,
    this.userId,
    this.equipmentId,
  });

  String labelStreet(String languageCode) =>
      streetNames.pickPreferRu(languageCode, fallback: street);

  String labelCity(String languageCode) =>
      cityNames.pickPreferRu(languageCode, fallback: city);

  String labelCountry(String languageCode) =>
      countryNames.pickPreferRu(languageCode, fallback: country);

  String streetLine(String languageCode) {
    return [
      labelStreet(languageCode),
      houseNumber?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(', ');
  }

  factory LocationModel.fromSearchResult(
    LocationSearchResult result, {
    required String service,
    String? equipmentId,
    double? latitude,
    double? longitude,
  }) {
    return LocationModel(
      service: service,
      street: result.street,
      streetNames: result.streetNames,
      houseNumber: result.houseNumber,
      city: result.city ?? '',
      cityNames: result.cityNames,
      country: result.country ?? '',
      countryNames: result.countryNames,
      region: result.region,
      regionNames: result.regionNames,
      latitude: latitude ?? result.latitude,
      longitude: longitude ?? result.longitude,
      equipmentId: equipmentId,
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['latitude']?.toString() ?? '');
    final lng = double.tryParse(json['longitude']?.toString() ?? '');

    if (lat == null || lat < -90 || lat > 90) {
      throw const FormatException("Invalid latitude");
    }
    if (lng == null || lng < -180 || lng > 180) {
      throw const FormatException("Invalid longitude");
    }

    final house = json['houseNumber']?.toString().trim();

    return LocationModel(
      id: json['id'],
      service: json['service'] ?? '',
      street: json['street'] ?? '',
      streetNames: LocalizedNames.fromJson(json['streetNames']),
      houseNumber: (house == null || house.isEmpty) ? null : house,
      city: json['city'] ?? '',
      cityNames: LocalizedNames.fromJson(json['cityNames']),
      country: json['country'] ?? '',
      countryNames: LocalizedNames.fromJson(json['countryNames']),
      region: json['region']?.toString(),
      regionNames: LocalizedNames.fromJson(json['regionNames']),
      comment: json['comment'] ?? '',
      instructions: json['instructions'] ?? '',
      latitude: lat,
      longitude: lng,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['userId'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "service": service,
      "street": street,
      "streetNames": streetNames.toJson(),
      "houseNumber": houseNumber,
      "city": city,
      "cityNames": cityNames.toJson(),
      "country": country,
      "countryNames": countryNames.toJson(),
      "region": region,
      "regionNames": regionNames.toJson(),
      "comment": comment,
      "instructions": instructions,
      "longitude": longitude,
      "latitude": latitude,
      "equipmentId": equipmentId,
    };
  }
}
