import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/models/owner_notification_preferences.dart';

enum OwnerType { individual, organization }

OwnerType? parseOwnerType(dynamic value) {
  if (value?.toString().trim().toLowerCase() == "individual") {
    return OwnerType.individual;
  }

  if (value?.toString().trim().toLowerCase() == "organization") {
    return OwnerType.organization;
  }

  return null;
}

class OwnerProfileModel {
  final String? id;

  final OwnerType? ownerType;
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

  final OwnerRegistrationStatus? status;
  final OwnerStatus onlineStatus;

  final bool? isVerified;
  final DateTime? verifiedAt;

  final OwnerNotificationPreferences notificationSettings;

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

    required this.onlineStatus,
    this.notificationSettings = const OwnerNotificationPreferences(),
  });

  OwnerProfileModel copyWith({
    String? id,
    OwnerType? ownerType,
    String? companyName,
    String? legalName,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    int? ratingAverage,
    int? ratingCount,
    int? orderCount,
    String? phoneNumber,
    String? email,
    String? city,
    String? region,
    String? iin,
    String? serviceDescription,
    String? serviceCities,
    OwnerRegistrationStatus? status,
    OwnerStatus? onlineStatus,
    bool? isVerified,
    DateTime? verifiedAt,
    OwnerNotificationPreferences? notificationSettings,
  }) {
    return OwnerProfileModel(
      id: id ?? this.id,
      ownerType: ownerType ?? this.ownerType,
      companyName: companyName ?? this.companyName,
      legalName: legalName ?? this.legalName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      orderCount: orderCount ?? this.orderCount,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      city: city ?? this.city,
      region: region ?? this.region,
      iin: iin ?? this.iin,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      serviceCities: serviceCities ?? this.serviceCities,
      status: status ?? this.status,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  factory OwnerProfileModel.fromJson(Map<String, dynamic> json) {
    return OwnerProfileModel(
      id: json['id']?.toString(),

      ownerType: parseOwnerType(json['ownerType']),
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
      status: parseOwnerRegistrationStatus(json['status']),

      isVerified: parseBoolean(json['isVerified']),
      verifiedAt: parseNullableDate(json['verifiedAt']),

      onlineStatus: parseOwnerStatus(json['onlineStatus']),
      notificationSettings: json['notificationSettings'] is Map
          ? OwnerNotificationPreferences.fromJson(
              Map<String, dynamic>.from(json['notificationSettings'] as Map),
            )
          : const OwnerNotificationPreferences(),
    );
  }

  Map<String, dynamic> toPatchJson() {
    return {
      'ownerType': ownerType?.name.toUpperCase(),
      'companyName': companyName,
      'legalName': legalName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'city': city,
      'serviceDescription': serviceDescription,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerType': ownerType?.name.toUpperCase(),
      'companyName': companyName,
      'legalName': legalName,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'orderCount': orderCount,
      'phoneNumber': phoneNumber,
      'email': email,
      'city': city,
      'region': region,
      'iin': iin,
      'serviceDescription': serviceDescription,
      'serviceCities': serviceCities,
      // Converts enums to their raw String names
      'status': status?.name,
      'onlineStatus': onlineStatus.name,
      'isVerified': isVerified,
      // Converts DateTime to an ISO 8601 string format
      'verifiedAt': verifiedAt?.toIso8601String(),
      // Calls toJson on the nested settings class
      'notificationSettings': notificationSettings.toJson(),
    };
  }
}
