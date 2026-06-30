import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';

class RequestModel {
  final String id;
  final RequestStatus status;
  final String capacity;
  final int offeredPrice;
  final PriceRateOption? offeredPriceRate;
  final String? comment;

  final DateTime? requiredOn;
  final DateTime? requiredAt;

  final LocationModel location;
  final User? client;

  final Category? category;
  final String? categoryId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  RequestModel({
    required this.id,
    required this.status,
    required this.capacity,
    required this.offeredPrice,
    this.offeredPriceRate,
    this.comment,

    this.requiredOn,
    this.requiredAt,

    required this.location,
    this.client,

    this.category,
    this.categoryId,

    this.createdAt,
    this.updatedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id']?.toString() ?? '',
      status: parseRequestStatus(json['status']),
      capacity: json['capacity']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',

      offeredPrice: parseNullableInt(json['offeredPrice']) ?? 0,
      offeredPriceRate: parseRateOption(json['offeredPriceRate']),

      requiredOn: DateTime.parse(json['requiredOn']),
      requiredAt: json['requiredAt'] != null
          ? DateTime.parse(json['requiredAt'])
          : null,

      categoryId: json['categoryId']?.toString() ?? '',
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,

      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : throw Exception("Location is required but missing"),

      client: json["client"] != null ? User.fromJson(json["client"]) : null,

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
      "id": id,
      "status": status,
      "category": category?.toJson(),
      "capacity": capacity,
      "offeredPrice": offeredPrice,
      "comment": comment,
      "location": location.toJson(),
      "client": client?.toJson(),
      "requiredOn": requiredOn?.toIso8601String(),
      "requiredAt": requiredAt?.toIso8601String(),
    };
  }
}
