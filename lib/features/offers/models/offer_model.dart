import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';

class OfferModel {
  final String id;
  final OfferStatus status;
  final String? comment;

  final String requestId;
  final String chatId;
  final String? bookingId;

  final String equipmentId;
  final EquipmentSummaryModel? equipment;
  final UserModel? owner;

  final int price;
  final PriceRateOption? priceRate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.priceRate,
    this.createdAt,
    this.updatedAt,
  });

  OfferModel copyWith({
    String? id,
    OfferStatus? status,
    String? comment,
    String? requestId,
    String? chatId,
    String? bookingId,
    String? equipmentId,
    EquipmentSummaryModel? equipment,
    UserModel? owner,
    int? price,
    PriceRateOption? priceRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      requestId: requestId ?? this.requestId,
      chatId: chatId ?? this.chatId,
      bookingId: bookingId ?? this.bookingId,
      equipmentId: equipmentId ?? this.equipmentId,
      equipment: equipment ?? this.equipment,
      owner: owner ?? this.owner,
      price: price ?? this.price,
      priceRate: priceRate ?? this.priceRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    try {
      return OfferModel(
        id: json['id']?.toString() ?? '',
        status: parseOfferStatus(json['status']),
        comment: json['comment']?.toString() ?? '',

        requestId: json['requestId']?.toString() ?? '',
        chatId: json['chatId']?.toString() ?? '',

        equipmentId: json['equipmentId']?.toString() ?? '',

        equipment: json['equipment'] != null
            ? EquipmentSummaryModel.fromJson(json['equipment'])
            : null,
        owner: json["owner"] != null ? UserModel.fromJson(json["owner"]) : null,

        bookingId: json['bookingId']?.toString().toLowerCase() == "null"
            ? null
            : json['bookingId']?.toString(),

        /// SAFE INT PARSING
        price: parseNullableInt(json['price']) ?? 0,
        priceRate: parseRateOption(json['priceRate']),

        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );
    } catch (error) {
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
