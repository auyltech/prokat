sealed class AuthCredentials {}

class LoginCredentials extends AuthCredentials {
  final String username;
  final String password;

  LoginCredentials({required this.username, required this.password});
}

class RegisterCredentials extends AuthCredentials {
  final String firstName;
  final String? lastName;
  final String username;
  final String password;

  RegisterCredentials({
    required this.username,
    required this.password,
    required this.firstName,
    this.lastName,
  });
}

class PhoneOtpCredentials extends AuthCredentials {
  final String phone;
  final String otp;

  PhoneOtpCredentials({required this.phone, required this.otp});
}
