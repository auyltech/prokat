import 'package:prokat/core/utils/parse.dart';

class VolumeDiscountModel {
  final int onlineCount;
  final int costPerEquipmentPerHour;

  VolumeDiscountModel({
    required this.onlineCount,
    required this.costPerEquipmentPerHour,
  });

  factory VolumeDiscountModel.fromJson(Map<String, dynamic> json) {
    try {
      return VolumeDiscountModel(
        onlineCount: parseInt(json['onlineCount'], fieldName: 'onlineCount'),
        costPerEquipmentPerHour: parseInt(
          json['costPerEquipmentPerHour'],
          fieldName: 'costPerEquipmentPerHour',
        ),
      );
    } catch (e, stackTrace) {
      throw FormatException(
        'Failed to parse VolumeDiscountModel: $e',
        stackTrace,
      );
    }
  }

  /// Parses a list of VolumeDiscounts, skipping any corrupted items.
  static List<VolumeDiscountModel> fromJsonList(dynamic jsonList) {
    if (jsonList is! List) return [];

    final List<VolumeDiscountModel> validItems = [];

    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;

      try {
        validItems.add(VolumeDiscountModel.fromJson(item));
      } catch (error) {
        // log('Skipping corrupted VolumeDiscount item. Error: $error', stackTrace: stackTrace);
      }
    }

    return validItems;
  }
}
