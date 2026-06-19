import 'package:prokat/features/auth/models/user_model.dart';

class AuthSession {
  final String? sessionToken;
  final DateTime? expires;
  final User? user;

  const AuthSession({this.sessionToken, this.user, this.expires});

  bool get isExpired {
    if (expires == null) return false;
    return DateTime.now().isAfter(expires!);
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      sessionToken: json['sessionToken'],
      expires: json['expires'] != null ? DateTime.parse(json['expires']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionToken': sessionToken,
      'expires': expires?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
