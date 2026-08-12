import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthSecureStorage defensive reads', () {
    test('removes an OTP session with an invalid requestedAt date', () async {
      FlutterSecureStorage.setMockInitialValues({
        _environmentKey('otp_session'): jsonEncode({
          'phone': '+77001234567',
          'requestedAt': 'not-a-date',
        }),
      });
      final storage = AuthSecureStorage();

      expect(await storage.readOtpSession(), isNull);
      expect(
        await SecureStorageClient.instance.read(
          key: _environmentKey('otp_session'),
        ),
        isNull,
      );
    });

    test('restores a valid OTP session', () async {
      const requestedAt = '2026-08-05T10:00:00.000Z';
      const retryAt = '2026-08-05T10:01:00.000Z';
      FlutterSecureStorage.setMockInitialValues({
        _environmentKey('otp_session'): jsonEncode({
          'phone': '+77001234567',
          'requestedAt': requestedAt,
          'retryAt': retryAt,
        }),
      });
      final storage = AuthSecureStorage();

      final result = await storage.readOtpSession();

      expect(result, isNotNull);
      expect(result!.phone, '+77001234567');
      expect(result.requestedAt, DateTime.parse(requestedAt));
      expect(result.retryAt, DateTime.parse(retryAt));
    });

    test('removes malformed OTP cooldown data', () async {
      FlutterSecureStorage.setMockInitialValues({
        _environmentKey('otp_cooldown'): jsonEncode({
          'phone': '+77001234567',
          'retryAt': 'not-a-date',
        }),
      });
      final storage = AuthSecureStorage();

      expect(await storage.readOtpCooldown(), isNull);
      expect(
        await SecureStorageClient.instance.read(
          key: _environmentKey('otp_cooldown'),
        ),
        isNull,
      );
    });

    test('removes a session with an invalid expiry date', () async {
      FlutterSecureStorage.setMockInitialValues({
        _environmentKey('auth_session'): jsonEncode({
          'sessionToken': 'token',
          'expires': 'not-a-date',
        }),
      });
      final storage = AuthSecureStorage();

      expect(await storage.readSession(), isNull);
      expect(
        await SecureStorageClient.instance.read(
          key: _environmentKey('auth_session'),
        ),
        isNull,
      );
    });
  });

  group('AppModeStorage defensive reads', () {
    test('removes an unknown app mode', () async {
      FlutterSecureStorage.setMockInitialValues({'app_mode': 'obsoleteMode'});
      final storage = AppModeStorage();

      expect(await storage.readMode(), isNull);
      expect(await SecureStorageClient.instance.read(key: 'app_mode'), isNull);
    });

    test('restores a valid app mode', () async {
      FlutterSecureStorage.setMockInitialValues({
        'app_mode': AppMode.ownerMode.name,
      });
      final storage = AppModeStorage();

      expect(await storage.readMode(), AppMode.ownerMode);
    });
  });
}

String _environmentKey(String key) => Env.isLocal ? 'local_$key' : key;
