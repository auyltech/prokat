import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingModel {
  final String id;
  final BookingStatus status;
  final WorkStatus workStatus;

  final DateTime? bookedOn;
  final DateTime? bookedAt;

  final int price;
  final String priceRate;

  final String? comment;
  final String? instructions;

  final String? chatId;

  final User? client;
  final User? owner;

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
    DateTime? tryParseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',

      status: parseBookingStatus(json['status']),
      workStatus: parseWorkStatus(json['workStatus']),

      bookedOn: tryParseDate(json['bookedOn']),
      bookedAt: tryParseDate(json['bookedAt']),

      price: (json['price'] as num?)?.toInt() ?? 0,
      priceRate: json['priceRate']?.toString() ?? '',

      comment: json['comment']?.toString(),
      instructions: json['instructions']?.toString(),

      chatId: json['chatId']?.toString(),

      myReviewId: json['myReviewId']?.toString(),

      client: json['client'] != null ? User.fromJson(json['client']) : null,
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,

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
      "priceRate": priceRate,
      "comment": comment,
      "instructions": instructions,
      "equipment": equipment?.toJson(),
      "location": location?.toJson(),
      "client": client?.toJson(),
      "owner": owner?.toJson(),
    };
  }
}
