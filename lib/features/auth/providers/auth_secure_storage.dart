import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/config/env.dart';
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
  static String get _authKey => _environmentKey('auth_session');
  static String get _otpKey => _environmentKey('otp_session');
  static String get _otpCooldownKey => _environmentKey('otp_cooldown');

  static String _environmentKey(String key) => Env.isLocal ? 'local_$key' : key;

  final FlutterSecureStorage _storage;

  AuthSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? SecureStorageClient.instance;

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: _authKey, value: jsonEncode(session.toJson()));
  }

  Future<AuthSession?> readSession() async {
    try {
      final value = await _storage.read(key: _authKey);

      if (value == null || value.isEmpty) return null;

      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid session format');
      }

      return AuthSession.fromJson(decoded);
    } catch (error) {
      try {
        await _storage.delete(key: _authKey);
      } catch (_) {}

      // A broken local session means signed out, not app failure.
      return null;
    }
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
    try {
      final value = await _storage.read(key: _otpKey);
      if (value == null || value.isEmpty) return null;

      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid OTP session format');
      }

      final phone = decoded['phone']?.toString();
      final requestedAt = DateTime.tryParse(
        decoded['requestedAt']?.toString() ?? '',
      );
      final retryAtValue = decoded['retryAt'];
      final retryAt = retryAtValue == null
          ? null
          : DateTime.tryParse(retryAtValue.toString());

      if (phone == null || phone.isEmpty || requestedAt == null) {
        throw const FormatException('Invalid OTP session data');
      }

      return OtpSessionData(
        phone: phone,
        requestedAt: requestedAt,
        retryAt: retryAt,
      );
    } catch (_) {
      await _deleteSilently(_otpKey);
      return null;
    }
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
    try {
      final value = await _storage.read(key: _otpCooldownKey);
      if (value == null || value.isEmpty) return null;

      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid OTP cooldown format');
      }

      final phone = decoded['phone']?.toString();
      final retryAt = DateTime.tryParse(decoded['retryAt']?.toString() ?? '');
      if (phone == null || phone.isEmpty || retryAt == null) {
        throw const FormatException('Invalid OTP cooldown data');
      }

      return OtpCooldownData(phone: phone, retryAt: retryAt);
    } catch (_) {
      await _deleteSilently(_otpCooldownKey);
      return null;
    }
  }

  Future<void> _deleteSilently(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // The storage itself may be unreadable; startup must still continue.
    }
  }

  Future<void> clearOtpCooldown() async {
    await _storage.delete(key: _otpCooldownKey);
  }
}
