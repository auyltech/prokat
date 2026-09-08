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

class UserModel {
  final String? id;
  final String? phoneNumber;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final int? rating;
  final int? orderCount;
  final UserRole? role;
  final String? imageUrl;

  const UserModel({
    this.id,
    this.phoneNumber,
    this.username,
    this.firstName,
    this.lastName,
    this.companyName,
    this.rating,
    this.orderCount,
    this.role,
    this.imageUrl,
  });

  @override
  String toString() {
    return 'User(firstName: $firstName, lastName: $lastName, username: $username)';
  }

  /// Given name, company name, or username. Phone is never a public label.
  String get displayName {
    final first = _publicLabel(firstName);
    final last = _publicLabel(lastName);
    if (first != null || last != null) {
      return [first, last].whereType<String>().join(' ');
    }

    return _publicLabel(companyName) ?? _publicLabel(username) ?? '';
  }

  String displayNameOr(String fallback) {
    final name = displayName;
    return name.isEmpty ? fallback : name;
  }

  static String? _publicLabel(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get isOwner {
    return role == UserRole.owner;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        username: json['username']?.toString(),
        companyName: json['companyName']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        rating: parseNullableInt(json['rating'] ?? json['ratingAverage']),
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
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'companyName': companyName,
      'role': role?.name.toUpperCase(),
      'imageUrl': imageUrl,
      'ratingAverage': rating,
      'orderCount': orderCount,
    };
  }
}
