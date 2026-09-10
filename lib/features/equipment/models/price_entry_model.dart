import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/parse.dart';

class PriceEntry {
  final String id;
  final int price;
  final PriceRateOption priceRate;
  final String? label;
  final bool isStartingFrom;

  PriceEntry({
    required this.id,
    required this.price,
    required this.priceRate,
    this.label,
    this.isStartingFrom = false,
  });

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    try {
      return PriceEntry(
        id: json["id"],
        price: parseNullableInt(json['price']) ?? 0,
        priceRate: parseRateOption(json["priceRate"]),
        label: json["label"]?.toString(),
        isStartingFrom: parseBoolean(json["isStartingFrom"]),
      );
    } catch (error) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "price": price,
      "priceRate": priceRate.value,
      "label": label,
      "isStartingFrom": isStartingFrom,
    };
  }

  PriceEntry copyWith({
    String? id,
    int? price,
    PriceRateOption? priceRate,
    String? label,
    bool? isStartingFrom,
  }) {
    return PriceEntry(
      id: id ?? this.id,
      price: price ?? this.price,
      priceRate: priceRate ?? this.priceRate,
      label: label ?? this.label,
      isStartingFrom: isStartingFrom ?? this.isStartingFrom,
    );
  }
}
