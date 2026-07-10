sealed class AuthCredentials {}

class PhoneOtpCredentials extends AuthCredentials {
  final String phone;
  final String otp;

  PhoneOtpCredentials({required this.phone, required this.otp});
}
