import 'package:prokat/core/utils/parse.dart';

class UserProfileModel {
  final String? username;
  final String? role;

  final String? firstName;
  final String? lastName;

  final String? phoneNumber;
  final bool? isPhoneVerified;

  final int? ratingStars;
  final int? ratingCount;
  final String? profileImageUrl;
  final DateTime? createdAt;

  final String? selectedCategoryId;
  final String? selectedAddressId;
  final String? city;
  final String? region;

  // Settings
  final String? darkMode;

  UserProfileModel({
    this.username,
    this.role,

    this.firstName,
    this.lastName,

    this.phoneNumber,
    this.isPhoneVerified,

    this.ratingStars,
    this.ratingCount,
    this.profileImageUrl,
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

    return username ?? "";
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserProfileModel(
        username: json['username']?.toString(),
        role: json['role']?.toString(),

        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),

        phoneNumber: json['phoneNumber']?.toString(),
        isPhoneVerified: parseBoolean(json['isPhoneVerified']),

        ratingStars: parseNullableInt(json['ratingStars']),
        ratingCount: parseNullableInt(json['ratingCount']),

        profileImageUrl: json['profileImageUrl']?.toString(),
        createdAt: parseNullableDate(json['createdAt']),

        selectedCategoryId: json['selectedCategoryId']?.toString(),
        selectedAddressId: json['selectedAddressId']?.toString(),

        city: json['city']?.toString(),
        region: json['region']?.toString(),

        darkMode: json['darkMode']?.toString(),
      );
    } catch (e, stack) {
      print("❌ User Profile parsing failed");
      print("JSON: $json");
      print(e);
      print(stack);
      rethrow; // important
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,

      'firstName': firstName,
      'lastName': lastName,

      'phoneNumber': phoneNumber,
      'isPhoneVerified': isPhoneVerified,

      'ratingStars': ratingStars,
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
