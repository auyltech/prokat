import 'package:prokat/core/utils/parse.dart';

class OwnerProfileModel {
  final String? id;

  final String? ownerType;
  final String? companyName;
  final String? legalName;

  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;

  final int? ratingAverage;
  final int? ratingCount;
  final int? orderCount;

  final String? phoneNumber;
  final String? email;
  final String? city;
  final String? region;

  final String? iin;

  final String? serviceDescription;
  final String? serviceCities;

  final String? status;

  final bool? isVerified;
  final DateTime? verifiedAt;

  OwnerProfileModel({
    this.id,

    this.ownerType,
    this.companyName,
    this.legalName,

    this.firstName,
    this.lastName,
    this.profileImageUrl,

    this.ratingAverage,
    this.ratingCount,
    this.orderCount,

    this.phoneNumber,
    this.email,
    this.city,
    this.region,
    this.iin,
    this.serviceDescription,
    this.serviceCities,
    this.status,
    this.isVerified,
    this.verifiedAt,
  });

  factory OwnerProfileModel.fromJson(Map<String, dynamic> json) {
    return OwnerProfileModel(
      id: json['id']?.toString(),

      ownerType: json['ownerType']?.toString(),
      companyName: json['companyName']?.toString(),
      legalName: json['legalName']?.toString(),

      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),

      ratingAverage: parseNullableInt(json['ratingAverage']),
      ratingCount: parseNullableInt(json['ratingCount']),
      orderCount: parseNullableInt(json['orderCount']),

      phoneNumber: json['phoneNumber']?.toString(),

      email: json['email']?.toString(),

      city: json['city']?.toString(),
      region: json['region']?.toString(),

      iin: json['iin']?.toString(),

      serviceDescription: json['serviceDescription']?.toString(),
      serviceCities: json['serviceCities']?.toString(),
      status: json['status']?.toString(),

      isVerified: parseBoolean(json['isVerified']),
      verifiedAt: parseNullableDate(json['verifiedAt']),
    );
  }
}
