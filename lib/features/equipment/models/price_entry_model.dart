import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/parse.dart';

class PriceEntry {
  final String id;
  final int price;
  final PriceRateOption priceRate;

  PriceEntry({required this.id, required this.price, required this.priceRate});

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    try {
      return PriceEntry(
        id: json["id"],
        price: parseNullableInt(json['price']) ?? 0,
        priceRate: parseRateOption(json["priceRate"]),
      );
    } catch (error) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "price": price, "priceRate": priceRate.value};
  }
}
