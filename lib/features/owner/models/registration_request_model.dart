class RegistrationRequestModel {
  final String? id;

  final String? firstName;
  final String? lastName;

  final String? phoneNumber;
  final String? email;

  final String? city;

  final String? message;
  final String? adminComment;
  final String? status;

  RegistrationRequestModel({
    this.id,

    this.firstName,
    this.lastName,

    this.phoneNumber,
    this.email,

    this.city,
    this.message,
    this.adminComment,
    this.status,
  });

  factory RegistrationRequestModel.fromJson(Map<String, dynamic> json) {
    try {
      return RegistrationRequestModel(
        id: json['id']?.toString(),

        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),

        phoneNumber: json['phoneNumber']?.toString(),
        email: json['email']?.toString(),
        city: json['city']?.toString(),

        message: json['message']?.toString(),
        adminComment: json['adminComment']?.toString(),
        status: json['status']?.toString(),
      );
    } catch (e, stack) {
      print("❌ Reqgistration request parsing failed");
      print("JSON: $json");
      print(e);
      print(stack);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'firstName': firstName,
      'lastName': lastName,

      'phoneNumber': phoneNumber,
      'email': email,
      'city': city,
      'message': message,
      'adminComment': adminComment,
      'status': status,
    };
  }
}
