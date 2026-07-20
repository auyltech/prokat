import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/models/equipment_location.dart';
import 'package:prokat/features/equipment/models/equipment_spec.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';

enum EquipmentStatus {
  draft,
  created,
  accepted,
  rejected,
  available,
  booked,
  maintenance,
  disabled,
  archived,
}

EquipmentStatus parseEquipmentStatus(dynamic value) {
  if (value == null) return EquipmentStatus.draft;

  final normalized = value.toString().trim().toLowerCase();

  for (final status in EquipmentStatus.values) {
    if (status.name.toLowerCase() == normalized) {
      return status;
    }
  }
  return EquipmentStatus.draft;
}

class Equipment {
  final String id;

  final String name;
  final String model;
  final String? plateNumber;

  final List<EquipmentSpec>? specs;

  final String capacity;
  final String capacityUnit;

  final String? ownerComment;
  final String? rentCondition;

  final EquipmentStatus status;
  final bool isVisible;

  final User? owner;
  final String? imageUrl;
  final List<EquipmentImage> images;

  final List<PriceEntry> prices;

  final String? city;
  final EquipmentLocation? location;

  final String? categoryId;
  final Category? category;

  final DateTime? updatedAt;

  Equipment({
    required this.id,
    required this.name,
    required this.model,
    this.plateNumber,
    this.specs,
    required this.capacity,
    required this.capacityUnit,
    this.ownerComment,
    this.rentCondition,
    required this.status,
    this.imageUrl,
    this.images = const [],
    required this.isVisible,
    this.owner,
    this.categoryId,
    this.category,
    this.city,
    this.location,
    required this.prices,
    this.updatedAt,
  });

  bool get isModerated => [
    EquipmentStatus.available,
    EquipmentStatus.accepted,
    EquipmentStatus.maintenance,
    EquipmentStatus.disabled,
  ].contains(status);

  bool get isDraft => [
    EquipmentStatus.draft,
    EquipmentStatus.created,
    EquipmentStatus.rejected,
  ].contains(status);

  String? get primaryImageUrl {
    for (final img in images) {
      if ((img.isPrimary ?? false) && img.imageUrl.isNotEmpty) {
        return img.imageUrl;
      }
    }

    final sorted = [...images]
      ..sort((a, b) => (a.order ?? 999999).compareTo(b.order ?? 999999));
    for (final img in sorted) {
      if (img.imageUrl.isNotEmpty) return img.imageUrl;
    }

    return imageUrl;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      "id": id,
      "name": name,
      "model": model,
      "plateNumber": plateNumber,
      if (specs != null) "specs": specs!.map((e) => e.toJson()).toList(),
      "capacity": capacity,
      "capacityUnit": capacityUnit,
      "rentCondition": rentCondition,
      "status": status,
      "isVisible": isVisible,
      "owner": owner,
      "category": category,
      "city": city,
      "updatedAt": updatedAt,
    };

    if (ownerComment != null) {
      data["ownerComment"] = ownerComment;
    }

    if (imageUrl != null) {
      data["imageUrl"] = imageUrl;
    }

    if (images.isNotEmpty) {
      data["images"] = images.map((e) => e.toJson()).toList();
    }

    if (prices.isNotEmpty) {
      data["prices"] = prices.map((e) => e.toJson()).toList();
    }

    if (location != null) {
      data["location"] = location;
    }

    return data;
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    try {
      final specs = (json["specs"] as List? ?? []).map((e) {
        try {
          return EquipmentSpec.fromJson(e);
        } catch (err) {
          throw Exception("EquipmentSpec parse failed: $err");
        }
      }).toList();

      return Equipment(
        id: json["id"] ?? '',

        name: json["name"] ?? '',
        model: json["model"] ?? '',
        plateNumber: json["plateNumber"] ?? '',

        specs: specs,

        capacity: json["capacity"].toString(),
        capacityUnit: json["capacityUnit"]?.toString() ?? '',

        ownerComment: json["ownerComment"] ?? "",
        rentCondition: json["rentCondition"],

        status: parseEquipmentStatus(json["status"]),
        isVisible: parseBoolean(json["isVisible"]),

        prices: (json["prices"] as List<dynamic>? ?? [])
            .map((e) => PriceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),

        imageUrl: json["imageUrl"] as String?,
        images: (json["images"] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(EquipmentImage.fromJson)
            .where((e) => e.imageUrl.isNotEmpty)
            .toList(),

        owner: json["owner"] is Map<String, dynamic>
            ? User.fromJson(json["owner"])
            : null,

        city: json["city"] ?? "",

        location: json['location'] != null
            ? EquipmentLocation.fromJson(json['location'])
            : null,

        categoryId: json["categoryId"]?.toString(),
        category: json["category"] is Map<String, dynamic>
            ? Category.fromJson(json["category"])
            : null,

        updatedAt: parseNullableDate(json['updatedAt']),
      );
    } catch (e) {
      throw Exception(
        "Failed to parse server data. Please ensure your app is up to date.",
      );
    }
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? model,
    String? plateNumber,
    List<EquipmentSpec>? specs,
    String? capacity,
    String? capacityUnit,
    String? ownerComment,
    String? rentCondition,
    EquipmentStatus? status,
    bool? isVisible,
    User? owner,
    String? imageUrl,
    List<EquipmentImage>? images,
    List<PriceEntry>? prices,
    String? city,
    EquipmentLocation? location,
    String? categoryId,
    Category? category,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      specs: specs ?? this.specs,
      capacity: capacity ?? this.capacity,
      capacityUnit: capacityUnit ?? this.capacityUnit,
      ownerComment: ownerComment ?? this.ownerComment,
      rentCondition: rentCondition ?? this.rentCondition,
      status: status ?? this.status,
      isVisible: isVisible ?? this.isVisible,
      owner: owner ?? this.owner,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      prices: prices ?? this.prices,
      city: city ?? this.city,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
