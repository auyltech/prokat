import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class OfferModel {
  final String id;
  final String status;
  final String? comment;

  /// Relations (optional)
  final RequestModel? request;
  final String requestId;

  final Equipment? equipment;
  final String equipmentId;

  final BookingModel? booking;
  final String? bookingId;

  final int price;
  final String priceRate;

  OfferModel({
    required this.id,
    required this.status,
    this.comment,

    required this.requestId,
    this.request,

    required this.equipmentId,
    this.equipment,

    this.bookingId,
    this.booking,

    required this.price,
    required this.priceRate,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    try {
      return OfferModel(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        comment: json['comment']?.toString() ?? '',

        requestId: json['requestId']?.toString() ?? '',

        // request: json['request'] != null
        //     ? RequestModel.fromJson(json['request'])
        //     : null,
        equipmentId: json['equipmentId']?.toString() ?? '',

        equipment: json['equipment'] != null
            ? Equipment.fromJson(json['equipment'])
            : null,
        bookingId: json['bookingId']?.toString(),
        // booking: json['booking'] != null
        //     ? BookingModel.fromJson(json['booking'])
        //     : null,

        /// 🔥 SAFE INT PARSING
        price: (json['price'] is int)
            ? json['price']
            : (json['price'] as num).toInt(),

        priceRate: json['priceRate']?.toString() ?? '',
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "status": status,
      "price": price,
      "priceRate": priceRate,

      /// ✅ IDs ONLY
      "requestId": requestId,
      "equipmentId": equipmentId,
      "bookingId": bookingId,
    };
  }
}
