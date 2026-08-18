import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';

void main() {
  const configuredEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );
  const configuredApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://prokat-backend.onrender.com',
  );
  const configuredSocketUrl = String.fromEnvironment('SOCKET_BASE_URL');
  const androidApiUrl = String.fromEnvironment('ANDROID_API_BASE_URL');
  const androidSocketUrl = String.fromEnvironment('ANDROID_SOCKET_BASE_URL');
  const pushEnabled = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: true,
  );
  const firebaseEnabled = bool.fromEnvironment(
    'ENABLE_FIREBASE_SERVICES',
    defaultValue: true,
  );

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('reads the selected environment', () {
    expect(
      Env.environment,
      configuredEnvironment == 'local'
          ? AppEnvironment.local
          : AppEnvironment.production,
    );
  });

  test('uses desktop API and socket endpoints on Windows', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    expect(Env.baseUrl, _withoutTrailingSlash(configuredApiUrl));
    expect(
      Env.socketUrl,
      _withoutTrailingSlash(
        configuredSocketUrl.isEmpty ? configuredApiUrl : configuredSocketUrl,
      ),
    );
    expect(Env.pushNotificationsEnabled, isFalse);
    expect(Env.firebaseServicesEnabled, firebaseEnabled);
  });

  test('uses Android-specific endpoints when configured', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(
      Env.baseUrl,
      _withoutTrailingSlash(
        androidApiUrl.isEmpty ? configuredApiUrl : androidApiUrl,
      ),
    );
    expect(
      Env.socketUrl,
      _withoutTrailingSlash(
        androidSocketUrl.isNotEmpty
            ? androidSocketUrl
            : configuredSocketUrl.isNotEmpty
            ? configuredSocketUrl
            : androidApiUrl.isNotEmpty
            ? androidApiUrl
            : configuredApiUrl,
      ),
    );
    expect(Env.pushNotificationsEnabled, pushEnabled);
    expect(Env.firebaseServicesEnabled, firebaseEnabled);
  });
}

String _withoutTrailingSlash(String value) {
  final trimmed = value.trim();
  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
