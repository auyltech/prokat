class PriceEntry {
  final String id;
  final int price;
  final String priceRate;
  final int serviceTime;

  PriceEntry({
    required this.id,
    required this.price,
    required this.priceRate,
    required this.serviceTime,
  });

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    try {
      return PriceEntry(
        id: json["id"],
        price: (json['price'] as num?)?.toInt() ?? 0,
        priceRate: json["priceRate"],
        serviceTime: (json['serviceTime'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "price": price,
      "priceRate": priceRate,
      "serviceTime": serviceTime,
    };
  }
}
