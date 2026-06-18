import 'package:prokat/core/utils/parse.dart';

enum UserRole { client, owner }

UserRole? parseUserRole(dynamic value) {
  if (value == null) return null;

  final normalized = value.toString().trim().toLowerCase();

  for (final role in UserRole.values) {
    if (role.name.toLowerCase() == normalized) {
      return role;
    }
  }

  return null;
}

class User {
  final String? id;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final int? rating;
  final int? orderCount;
  final UserRole? role;
  final String? imageUrl;

  const User({
    this.id,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.rating,
    this.orderCount,
    this.role,
    this.imageUrl,
  });

  @override
  String toString() {
    return 'User(firstName: $firstName, lastName: $lastName, phoneNumber: $phoneNumber)';
  }

  String get displayName {
    // Check if at least one name field has text
    if ((firstName != null && firstName!.trim().isNotEmpty) ||
        (lastName != null && lastName!.trim().isNotEmpty)) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }

    // Fallback to phone, or "User" if phone is also missing
    return (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        ? phoneNumber!.trim()
        : "User";
  }

  bool get isOwner {
    return role == UserRole.owner;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        rating: parseNullableInt(json['rating']),
        orderCount: parseNullableInt(json['orderCount']),
        role: parseUserRole(json['role']) ?? UserRole.client,
        imageUrl: json['imageUrl']?.toString(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'role': role?.name.toUpperCase(),
      'imageUrl': imageUrl,
      'ratingAverage': rating,
      'orderCount': orderCount,
    };
  }
}
