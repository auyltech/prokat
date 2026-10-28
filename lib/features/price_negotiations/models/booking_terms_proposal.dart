import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingTermsSnapshot {
  final int price;
  final PriceRateOption? priceRate;
  final DateTime bookedOn;
  final DateTime bookedAt;
  final LocationModel? location;

  const BookingTermsSnapshot({
    required this.price,
    required this.priceRate,
    required this.bookedOn,
    required this.bookedAt,
    required this.location,
  });

  factory BookingTermsSnapshot.fromJson(Map<String, dynamic> json) =>
      BookingTermsSnapshot(
        price: (json['price'] as num).toInt(),
        priceRate: parseKnownRateOption(json['priceRate']),
        bookedOn: DateTime.parse(json['bookedOn'] as String),
        bookedAt: DateTime.parse(json['bookedAt'] as String),
        location: json['location'] is Map
            ? LocationModel.fromJson(
                Map<String, dynamic>.from(json['location'] as Map),
              )
            : null,
      );
}

class BookingTermsProposal {
  final int version;
  final DateTime bookedOn;
  final DateTime bookedAt;
  final LocationModel location;
  final BookingTermsSnapshot previous;

  const BookingTermsProposal({
    required this.version,
    required this.bookedOn,
    required this.bookedAt,
    required this.location,
    required this.previous,
  });

  static BookingTermsProposal? tryParse(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    try {
      return BookingTermsProposal(
        version: 1,
        bookedOn: DateTime.parse(value['bookedOn'] as String),
        bookedAt: DateTime.parse(value['bookedAt'] as String),
        location: LocationModel.fromJson(
          Map<String, dynamic>.from(value['location'] as Map),
        ),
        previous: BookingTermsSnapshot.fromJson(
          Map<String, dynamic>.from(value['previous'] as Map),
        ),
      );
    } on Object {
      return null;
    }
  }
}
