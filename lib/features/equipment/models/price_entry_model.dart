import 'package:prokat/core/utils/parse.dart';

class PriceEntry {
  final String id;
  final int price;
  final String priceRate;

  PriceEntry({required this.id, required this.price, required this.priceRate});

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    return PriceEntry(
      id: json["id"],
      price: parseNullableInt(json['price']) ?? 0,
      priceRate: json["priceRate"],
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "price": price, "priceRate": priceRate};
  }
}
