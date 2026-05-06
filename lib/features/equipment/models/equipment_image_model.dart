import 'package:prokat/core/utils/parse.dart';

class EquipmentImage {
  final String id;
  final String imageUrl;
  final bool? isPrimary;
  final int? order;
  final DateTime? createdAt;

  const EquipmentImage({
    required this.id,
    required this.imageUrl,
    this.isPrimary = false,
    this.order,
    this.createdAt,
  });

  factory EquipmentImage.fromJson(Map<String, dynamic> json) {
    return EquipmentImage(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isPrimary: parseBoolean(json['isPrimary']),
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse('${json['order']}'),
      createdAt: parseNullableDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'isPrimary': isPrimary,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
