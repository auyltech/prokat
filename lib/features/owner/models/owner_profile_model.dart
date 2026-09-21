import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/owner/models/owner_profile_pending_change.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/models/owner_notification_preferences.dart';

enum OwnerType { individual, organization }

OwnerType? parseOwnerType(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'individual') return OwnerType.individual;
  // API uses BUSINESS; older clients may still say organization.
  if (normalized == 'business' || normalized == 'organization') {
    return OwnerType.organization;
  }
  return null;
}

String? ownerTypeToApi(OwnerType? type) {
  return switch (type) {
    OwnerType.individual => 'INDIVIDUAL',
    OwnerType.organization => 'BUSINESS',
    null => null,
  };
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
  final String? adminComment;
  final DateTime? correctionDeadlineAt;
  final bool isCorrectionOverdue;
  final List<OwnerProfilePendingChange> pendingChanges;

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
    this.adminComment,
    this.correctionDeadlineAt,
    this.isCorrectionOverdue = false,
    this.pendingChanges = const [],

    required this.onlineStatus,
    this.notificationSettings = const OwnerNotificationPreferences(),
  });

  /// Live profile keeps approved values; overlay proposed `to` for draft edit/display.
  OwnerProfileModel withPendingDraftApplied() {
    if (pendingChanges.isEmpty) return this;

    String? valueFor(String field) {
      for (final change in pendingChanges) {
        if (change.field == field) return change.to;
      }
      return null;
    }

    String? pick(String field, String? current) {
      final proposed = valueFor(field);
      if (proposed == null) return current;
      final trimmed = proposed.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    OwnerType? nextType = ownerType;
    final typeRaw = valueFor('ownerType');
    if (typeRaw != null) {
      nextType = parseOwnerType(typeRaw) ?? ownerType;
    }

    return copyWith(
      ownerType: nextType,
      companyName: pick('companyName', companyName),
      legalName: pick('legalName', legalName),
      firstName: pick('firstName', firstName),
      lastName: pick('lastName', lastName),
      phoneNumber: pick('phoneNumber', phoneNumber),
      email: pick('email', email),
      city: pick('city', city),
      region: pick('region', region),
      iin: pick('iin', iin),
      serviceDescription: pick('serviceDescription', serviceDescription),
      serviceCities: pick('serviceCities', serviceCities),
    );
  }

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
    String? adminComment,
    DateTime? correctionDeadlineAt,
    bool? isCorrectionOverdue,
    List<OwnerProfilePendingChange>? pendingChanges,
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
      adminComment: adminComment ?? this.adminComment,
      correctionDeadlineAt: correctionDeadlineAt ?? this.correctionDeadlineAt,
      isCorrectionOverdue: isCorrectionOverdue ?? this.isCorrectionOverdue,
      pendingChanges: pendingChanges ?? this.pendingChanges,
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
      adminComment: json['adminComment']?.toString(),
      correctionDeadlineAt: parseNullableDate(json['correctionDeadlineAt']),
      isCorrectionOverdue: parseBoolean(json['isCorrectionOverdue']),
      pendingChanges: parseOwnerProfilePendingChanges(json['pendingChanges']),

      onlineStatus: parseOwnerStatus(json['onlineStatus']),
      notificationSettings: json['notificationSettings'] is Map
          ? OwnerNotificationPreferences.fromJson(
              Map<String, dynamic>.from(json['notificationSettings'] as Map),
            )
          : const OwnerNotificationPreferences(),
    );
  }

  Map<String, dynamic> toPatchJson() {
    // Backend: z.string().min(1).optional().nullable() — empty "" fails validation.
    String? nonEmptyOrNull(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    }

    return {
      'ownerType': ownerTypeToApi(ownerType),
      'companyName': nonEmptyOrNull(companyName),
      'legalName': nonEmptyOrNull(legalName),
      'firstName': nonEmptyOrNull(firstName),
      'lastName': nonEmptyOrNull(lastName),
      'phoneNumber': nonEmptyOrNull(phoneNumber),
      'city': nonEmptyOrNull(city),
      'serviceDescription': nonEmptyOrNull(serviceDescription),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerType': ownerTypeToApi(ownerType),
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
      'status': status?.name,
      'onlineStatus': onlineStatus.name,
      'isVerified': isVerified,
      'adminComment': adminComment,
      'correctionDeadlineAt': correctionDeadlineAt?.toIso8601String(),
      'isCorrectionOverdue': isCorrectionOverdue,
      'pendingChanges': pendingChanges.map((c) => c.toJson()).toList(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'notificationSettings': notificationSettings.toJson(),
    };
  }
}
