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
    defaultValue: 'https://api.prokat.auyltech.kz',
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

  test('builds an equipment share URL on the default host', () {
    expect(Env.shareBaseUrl, 'https://prokat-bfbec.web.app');
    expect(
      Env.equipmentShareUrl('equipment-1'),
      'https://prokat-bfbec.web.app/e/equipment-1',
    );
    expect(Env.shareTrustedHosts, {
      'prokat-bfbec.web.app',
      'prokat-bfbec.firebaseapp.com',
    });
  });

  test('rejects a share URL that is not bare https', () {
    expect(
      () => Env.parseShareBaseUrl('http://prokat-bfbec.web.app'),
      throwsStateError,
    );
    expect(
      () => Env.parseShareBaseUrl('https://prokat-bfbec.web.app/'),
      throwsStateError,
    );
    expect(
      () => Env.parseShareBaseUrl('https://prokat-bfbec.web.app/e/1'),
      throwsStateError,
    );
    expect(
      Env.parseShareBaseUrl('https://links.example.com'),
      'https://links.example.com',
    );
    expect(() => Env.equipmentShareUrl(''), throwsArgumentError);
    expect(() => Env.equipmentShareUrl('a/b'), throwsArgumentError);
  });
}

String _withoutTrailingSlash(String value) {
  final trimmed = value.trim();
  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
