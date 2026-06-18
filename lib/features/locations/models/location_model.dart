class LocationModel {
  final String? id;
  final String service; // "EQUIPMENT" | "ADDRESS"

  final String street;
  final String city;
  final String country;

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
    required this.city,
    required this.country,
    required this.longitude,
    required this.latitude,
    this.createdAt,
    this.updatedAt,
    this.comment,
    this.instructions,
    this.userId,
    this.equipmentId,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing with range validation
    final lat = double.tryParse(json['latitude']?.toString() ?? '');
    final lng = double.tryParse(json['longitude']?.toString() ?? '');

    // Ensure coordinates are valid and within global geographic bounds
    if (lat == null || lat < -90 || lat > 90) {
      throw const FormatException("Invalid latitude");
    }
    if (lng == null || lng < -180 || lng > 180) {
      throw const FormatException("Invalid longitude");
    }

    return LocationModel(
      id: json['id'],
      service: json['service'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
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
      "city": city,
      "country": country,
      "comment": comment,
      "instructions": instructions,
      "longitude": longitude,
      "latitude": latitude,
      "equipmentId": equipmentId,
    };
  }
}
