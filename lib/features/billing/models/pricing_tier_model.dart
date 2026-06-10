import 'package:prokat/core/utils/parse.dart';

class PricingTierModel {
  final String id;
  final String label;
  final int minutes;
  final int price;
  final int sortIndex;

  PricingTierModel({
    required this.id,
    required this.label,
    required this.price,
    required this.minutes,
    required this.sortIndex,
  });

  factory PricingTierModel.fromJson(Map<String, dynamic> json) {
    try {
      return PricingTierModel(
        id: parseString(json['id'], fieldName: 'id'),
        label: parseString(json['label'], fieldName: 'label'),
        price: parseInt(json['price'], fieldName: 'price'),
        minutes: parseInt(json['minutes'], fieldName: 'minutes'),
        sortIndex: parseInt(json['sortIndex'], fieldName: 'sortIndex'),
      );
    } catch (error) {
      throw Exception('Failed to parse PriceTierModel: $error');
    }
  }

  static List<PricingTierModel> fromJsonList(dynamic jsonList) {
    if (jsonList is! List) return [];

    final List<PricingTierModel> validItems = [];

    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;

      try {
        validItems.add(PricingTierModel.fromJson(item));
      } catch (error) {
        // log('Skipping corrupted PricingTier item. Error: $error', stackTrace: stackTrace);
      }
    }

    return validItems;
  }
}
