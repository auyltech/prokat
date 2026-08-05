import 'package:prokat/features/auth/models/user_model.dart';

class AuthSession {
  final String? sessionToken;
  final DateTime? expires;
  final UserModel? user;

  const AuthSession({this.sessionToken, this.user, this.expires});

  bool get isExpired {
    if (expires == null) return false;
    return DateTime.now().isAfter(expires!);
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final expiresValue = json['expires'];
    final expires = expiresValue == null
        ? null
        : DateTime.tryParse(expiresValue.toString());

    if (expiresValue != null && expires == null) {
      throw const FormatException('Invalid session expiry date');
    }

    return AuthSession(
      sessionToken: json['sessionToken'],
      expires: expires,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
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
