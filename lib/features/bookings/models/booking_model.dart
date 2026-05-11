import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingEquiment {
  final String? id;

  final String? name;
  final String? model;
  final String? plateNumber;

  final String? imageUrl;

  final String? ownerId;
  final String? ownerName;

  BookingEquiment({
    this.id,
    this.name,
    this.model,
    this.plateNumber,
    this.imageUrl,
    this.ownerId,
    this.ownerName,
  });

  factory BookingEquiment.fromJson(Map<String, dynamic> json) {
    return BookingEquiment(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      model: json['model'] ?? "",
      plateNumber: json['plateNumber'] ?? "",
      imageUrl: json['imageUrl'] ?? "",
      ownerId: json['ownerId'] ?? "",
      ownerName: json['ownerName'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "model": model,
      "plateNumber": plateNumber,
      "imageUrl": imageUrl,
      "ownerId": ownerId,
      "ownerName": ownerName,
    };
  }
}

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

      return BookingModel(
        id: json['id']?.toString() ?? '',

        status: json['status']?.toString() ?? '',

        bookedOn: tryParseDate(json['bookedOn']),
        bookedAt: tryParseDate(json['bookedAt']),

        price: (json['price'] as num?)?.toInt() ?? 0,
        priceRate: json['priceRate']?.toString() ?? '',

        comment: json['comment']?.toString(),
        instructions: json['instructions']?.toString(),

        chatId: json['chatId']?.toString(),

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
      print("***** BOOKING PARSE FAILED");
      print(e);
      print(json);
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
