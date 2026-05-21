class User {
  final String? id;
  final String? username;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? role;
  final String? imageUrl;

  const User({
    this.id,
    this.username,
    this.phoneNumber,
    this.firstName,
    this.lastName,
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

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        username: json['username']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        role: json['role']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'imageUrl': imageUrl,
    };
  }
}
