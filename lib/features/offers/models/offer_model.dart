import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';

class OfferModel {
  final String id;
  final String status;
  final String? comment;

  final String requestId;
  final String chatId;
  final String? bookingId;

  final String equipmentId;
  final EquipmentSummaryModel? equipment;
  final User? owner;

  final int price;
  final String priceRate;

  final DateTime? createdAt;
  OfferModel({
    required this.id,
    required this.status,
    this.comment,

    required this.requestId,
    required this.chatId,
    required this.equipmentId,

    this.equipment,
    this.owner,

    this.bookingId,

    required this.price,
    required this.priceRate,
    this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    try {
      return OfferModel(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        comment: json['comment']?.toString() ?? '',

        requestId: json['requestId']?.toString() ?? '',
        chatId: json['chatId']?.toString() ?? '',

        equipmentId: json['equipmentId']?.toString() ?? '',

        equipment: json['equipment'] != null
            ? EquipmentSummaryModel.fromJson(json['equipment'])
            : null,
        owner: json["owner"] != null ? User.fromJson(json["owner"]) : null,

        bookingId: json['bookingId']?.toString(),

        /// SAFE INT PARSING
        price: parseNullableInt(json['price']) ?? 0,
        priceRate: json['priceRate']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );
    } catch (e) {
      print("parse_failed:offer_model");
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
