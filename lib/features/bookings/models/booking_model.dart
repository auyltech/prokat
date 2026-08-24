import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/utils/date_time.dart';

class BookingModel {
  final String id;
  final BookingStatus status;
  final WorkStatus workStatus;

  final DateTime? bookedOn;
  final DateTime? bookedAt;

  final int price;
  final PriceRateOption priceRate;

  final String? comment;
  final String? instructions;

  final String? chatId;

  final UserModel? client;
  final UserModel? owner;

  final EquipmentSummaryModel? equipment;
  final LocationModel? location;

  final String? myReviewId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.status,
    this.workStatus = WorkStatus.pending,
    this.bookedOn,
    this.bookedAt,
    required this.price,
    required this.priceRate,
    this.comment,
    this.instructions,
    this.chatId,
    this.client,
    this.owner,
    this.equipment,
    this.location,

    this.myReviewId,
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',

      status: parseBookingStatus(json['status']),
      workStatus: parseWorkStatus(json['workStatus']),

      bookedOn: parseLocalDateTime(json['bookedOn']),
      bookedAt: parseLocalDateTime(json['bookedAt']),

      price: (json['price'] as num?)?.toInt() ?? 0,
      priceRate: parseRateOption(json['priceRate']),

      comment: json['comment']?.toString(),
      instructions: json['instructions']?.toString(),

      chatId: json['chatId']?.toString(),

      myReviewId: json['myReviewId']?.toString(),

      client: json['client'] != null
          ? UserModel.fromJson(json['client'])
          : null,
      owner: json['owner'] != null ? UserModel.fromJson(json['owner']) : null,

      equipment: json['equipment'] != null
          ? EquipmentSummaryModel.fromJson(json['equipment'])
          : null,

      location: json['location'] != null
          ? () {
              try {
                return LocationModel.fromJson(json['location']);
              } catch (e) {
                // Log the error here if you use a logging framework
                return null;
              }
            }()
          : null,

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "status": status,
      "bookedOn": bookedOn?.toIso8601String(),
      "bookedAt": bookedAt?.toIso8601String(),
      "price": price,
      "priceRate": priceRate.value,
      "comment": comment,
      "instructions": instructions,
      "equipment": equipment?.toJson(),
      "location": location?.toJson(),
      "client": client?.toJson(),
      "owner": owner?.toJson(),
    };
  }
}
