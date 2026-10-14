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
    expect(Env.pushNotificationsEnabled, firebaseEnabled && pushEnabled);
    expect(Env.firebaseServicesEnabled, firebaseEnabled);
  });

  test('disables analytics collection without firebase services', () {
    expect(Env.analyticsCollectionEnabled, isFalse);
  }, skip: firebaseEnabled ? 'requires ENABLE_FIREBASE_SERVICES=false' : false);

  test('builds only canonical token URLs and keeps legacy inbound hosts', () {
    const token = 'AbCdEfGhIjKlMnOpQr_-12';
    expect(Env.shareBaseUrl, 'https://prokat.auyltech.kz');
    expect(
      Env.publicEquipmentShareUrl(token),
      'https://prokat.auyltech.kz/e/$token',
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
      () => Env.parseShareBaseUrl('https://links.example.com'),
      throwsStateError,
    );
    expect(
      () => Env.parseShareBaseUrl('https://open.prokat.auyltech.kz'),
      throwsStateError,
    );
    expect(
      () => Env.parseShareBaseUrl('https://prokat-bfbec.web.app'),
      throwsStateError,
    );
    expect(() => Env.publicEquipmentShareUrl(''), throwsArgumentError);
    expect(() => Env.publicEquipmentShareUrl('a/b'), throwsArgumentError);
  });

  test('share url with share id', () {
    const shareId = 'AbCdEfGhIjKlMnOpQr_-12';
    expect(
      Env.publicEquipmentShareUrl(shareId),
      'https://prokat.auyltech.kz/e/$shareId',
    );
    expect(
      Uri.parse(Env.publicEquipmentShareUrl(shareId)).queryParameters,
      isEmpty,
    );
  });

  test('invalid share id throws', () {
    expect(() => Env.publicEquipmentShareUrl(''), throwsArgumentError);
    expect(() => Env.publicEquipmentShareUrl('a' * 21), throwsArgumentError);
    expect(() => Env.publicEquipmentShareUrl('a' * 23), throwsArgumentError);
    expect(
      () => Env.publicEquipmentShareUrl('AbCdEfGhIjKlMnOpQrSt=='),
      throwsArgumentError,
    );
  });
}

String _withoutTrailingSlash(String value) {
  final trimmed = value.trim();
  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
