import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/equipment/models/booking_equipment_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingModel {
  final String id;
  final String status;
  final WorkStatus workStatus;

  final DateTime? bookedOn;
  final DateTime? bookedAt;

  final int price;
  final String priceRate;

  final String? comment;
  final String? instructions;

  final String? chatId;

  final User? renter;

  final BookingEquiment? equipment;
  final LocationModel location;

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
    this.renter,
    this.equipment,
    required this.location,

    this.myReviewId,
    this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      DateTime? tryParseDate(dynamic value) {
        if (value == null) return null;
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }

      WorkStatus parseWorkStatus(dynamic value) {
        if (value == null) return WorkStatus.pending;
        final normalized = value.toString().trim().toLowerCase();
        for (final status in WorkStatus.values) {
          if (status.name.toLowerCase() == normalized) {
            return status;
          }
        }
        return WorkStatus.pending;
      }

      return BookingModel(
        id: json['id']?.toString() ?? '',

        status: json['status']?.toString() ?? '',
        workStatus: parseWorkStatus(json['workStatus']),

        bookedOn: tryParseDate(json['bookedOn']),
        bookedAt: tryParseDate(json['bookedAt']),

        price: (json['price'] as num?)?.toInt() ?? 0,
        priceRate: json['priceRate']?.toString() ?? '',

        comment: json['comment']?.toString(),
        instructions: json['instructions']?.toString(),

        chatId: json['chatId']?.toString(),

        myReviewId: json['myReviewId']?.toString(),

        renter: json['renter'] != null ? User.fromJson(json['renter']) : null,

        equipment: json['equipment'] != null
            ? BookingEquiment.fromJson(json['equipment'])
            : null, //throw Exception("Equipment is required but missing"),

        location: json['location'] != null
            ? LocationModel.fromJson(json['location'])
            : throw Exception("Location is required but missing"),

        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,

        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );
    } catch (e) {
      print("booking_parse_failed");
      rethrow;
    }
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
      "location": location.toJson(),
      "renter": renter?.toJson(),
    };
  }
}
