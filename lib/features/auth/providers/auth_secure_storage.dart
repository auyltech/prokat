import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import '../models/auth_session.dart';

class OtpSessionData {
  final String phone;
  final DateTime requestedAt;
  final DateTime? retryAt;

  OtpSessionData({
    required this.phone,
    required this.requestedAt,
    this.retryAt,
  });
}

class OtpCooldownData {
  final String phone;
  final DateTime retryAt;

  OtpCooldownData({required this.phone, required this.retryAt});
}

class AuthSecureStorage {
  static const _authKey = 'auth_session';
  static const _otpKey = 'otp_session';
  static const _otpCooldownKey = 'otp_cooldown';

  final FlutterSecureStorage _storage;

  AuthSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? SecureStorageClient.instance;

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

  Future<void> saveOtpSession(
    String phone,
    DateTime time, {
    DateTime? retryAt,
  }) async {
    await _storage.write(
      key: _otpKey,
      value: jsonEncode({
        'phone': phone,
        'requestedAt': time.toIso8601String(),
        'retryAt': retryAt?.toIso8601String(),
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
      retryAt: DateTime.tryParse(json['retryAt']?.toString() ?? ''),
    );
  }

  Future<void> clearOtpSession() async {
    await _storage.delete(key: _otpKey);
  }

  Future<void> saveOtpCooldown(String phone, DateTime retryAt) async {
    await _storage.write(
      key: _otpCooldownKey,
      value: jsonEncode({'phone': phone, 'retryAt': retryAt.toIso8601String()}),
    );
  }

  Future<OtpCooldownData?> readOtpCooldown() async {
    final value = await _storage.read(key: _otpCooldownKey);
    if (value == null) return null;

    try {
      final json = jsonDecode(value);
      final phone = json['phone']?.toString();
      final retryAt = DateTime.tryParse(json['retryAt']?.toString() ?? '');
      if (phone == null || phone.isEmpty || retryAt == null) return null;
      return OtpCooldownData(phone: phone, retryAt: retryAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearOtpCooldown() async {
    await _storage.delete(key: _otpCooldownKey);
  }
}
