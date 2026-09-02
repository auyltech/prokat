import 'package:prokat/features/catalog/models/localized_names.dart';

class EquipmentLocation {
  final String id;
  final String street;
  final LocalizedNames streetNames;
  final String? houseNumber;
  final String? city;
  final LocalizedNames cityNames;
  final double? longitude;
  final double? latitude;

  EquipmentLocation({
    required this.id,
    required this.street,
    this.streetNames = const LocalizedNames(),
    this.houseNumber,
    this.longitude,
    this.latitude,
    this.city,
    this.cityNames = const LocalizedNames(),
  });

  String labelStreet(String languageCode) =>
      streetNames.pickPreferRu(languageCode, fallback: street);

  String streetLine(String languageCode) {
    return [
      labelStreet(languageCode),
      houseNumber?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(', ');
  }

  factory EquipmentLocation.fromJson(Map<String, dynamic> json) {
    final house = json['houseNumber']?.toString().trim();

    return EquipmentLocation(
      id: json["id"],
      street: json["street"] ?? '',
      streetNames: LocalizedNames.fromJson(json['streetNames']),
      houseNumber: (house == null || house.isEmpty) ? null : house,
      city: json["city"],
      cityNames: LocalizedNames.fromJson(json['cityNames']),
      longitude: double.tryParse(json["longitude"].toString()) ?? 0,
      latitude: double.tryParse(json["latitude"].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "street": street,
      "streetNames": streetNames.toJson(),
      "houseNumber": houseNumber,
      "city": city,
      "cityNames": cityNames.toJson(),
      "longitude": longitude,
      "latitude": latitude,
    };
  }
}
