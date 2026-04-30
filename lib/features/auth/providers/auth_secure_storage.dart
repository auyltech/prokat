import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_session.dart';

class OtpSessionData {
  final String phone;
  final DateTime requestedAt;

  OtpSessionData({required this.phone, required this.requestedAt});
}

class AuthSecureStorage {
  static const _authKey = 'auth_session';
  static const _otpKey = 'otp_session';

  final _storage = const FlutterSecureStorage();

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _authKey, value: jsonEncode(session.toJson()));
  }

  Future<AuthSession?> readSession() async {
    final value = await _storage.read(key: _authKey);

    if (value == null) return null;

    return AuthSession.fromJson(jsonDecode(value));
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _authKey);
  }

  Future<void> saveOtpSession(String phone, DateTime time) async {
    await _storage.write(
      key: _otpKey,
      value: jsonEncode({
        'phone': phone,
        'requestedAt': time.toIso8601String(),
      }),
    );
  }

  Future<OtpSessionData?> readOtpSession() async {
    final value = await _storage.read(key: _otpKey);
    if (value == null) return null;

    final json = jsonDecode(value);

    return OtpSessionData(
      phone: json['phone'],
      requestedAt: DateTime.parse(json['requestedAt']),
    );
  }

  Future<void> clearOtpSession() async {
    await _storage.delete(key: _otpKey);
  }
}
