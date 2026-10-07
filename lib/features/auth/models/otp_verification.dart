import 'package:prokat/features/auth/models/auth_session.dart';

class OtpVerification {
  final AuthSession session;
  final bool isNewUser;

  const OtpVerification({required this.session, required this.isNewUser});
}
