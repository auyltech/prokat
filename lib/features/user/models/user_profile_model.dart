import 'package:prokat/core/utils/parse.dart';

class UserProfileModel {
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;

  final String? phoneNumber;
  final bool? isPhoneVerified;

  final int? ratingAverage;
  final int? ratingCount;
  final int? orderCount;

  final String? selectedCategoryId;
  final String? selectedAddressId;
  final String? city;
  final String? region;

  final String? role;
  final DateTime? createdAt;

  // Settings
  final String? darkMode;

  UserProfileModel({
    this.role,

    this.firstName,
    this.lastName,
    this.profileImageUrl,

    this.phoneNumber,
    this.isPhoneVerified,

    this.ratingAverage,
    this.ratingCount,
    this.orderCount,

    this.createdAt,

    this.selectedCategoryId,
    this.selectedAddressId,
    this.city,
    this.region,

    this.darkMode,
  });

  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }

    return "";
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserProfileModel(
        role: json['role']?.toString(),

        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        profileImageUrl: json['profileImageUrl']?.toString(),

        phoneNumber: json['phoneNumber']?.toString(),
        isPhoneVerified: parseBoolean(json['isPhoneVerified']),

        ratingAverage: parseNullableInt(json['ratingAverage']),
        ratingCount: parseNullableInt(json['ratingCount']),
        orderCount: parseNullableInt(json['orderCount']),

        createdAt: parseNullableDate(json['createdAt']),

        selectedCategoryId: json['selectedCategoryId']?.toString(),
        selectedAddressId: json['selectedAddressId']?.toString(),

        city: json['city']?.toString(),
        region: json['region']?.toString(),

        darkMode: json['darkMode']?.toString(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,

      'firstName': firstName,
      'lastName': lastName,

      'phoneNumber': phoneNumber,
      'isPhoneVerified': isPhoneVerified,

      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,

      'selectedCategoryId': selectedCategoryId,
      'selectedAddressId': selectedAddressId,
      'city': city,
      'region': region,

      'darkMode': darkMode,
    };
  }
}
