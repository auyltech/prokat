class User {
  final String? id;
  final String? username;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? role;
  final String? imageUrl;

  const User({
    this.id,
    this.username,
    this.phone,
    this.firstName,
    this.lastName,
    this.role,
    this.imageUrl,
  });

  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return username ?? "User";
  }

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        username: json['username']?.toString(),
        phone: json['phone']?.toString(),
        role: json['role']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
      );
    } catch (e, stack) {
      print("❌ User parsing failed");
      print("JSON: $json");
      print(e);
      print(stack);
      rethrow; // important
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'imageUrl': imageUrl,
    };
  }
}
