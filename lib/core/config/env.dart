import 'package:flutter/foundation.dart';

enum AppEnvironment { production, local }

class Env {
  static const _productionBaseUrl = 'https://api.prokat.auyltech.kz';

  static const _environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _productionBaseUrl,
  );
  static const _socketBaseUrl = String.fromEnvironment('SOCKET_BASE_URL');
  static const _androidApiBaseUrl = String.fromEnvironment(
    'ANDROID_API_BASE_URL',
  );
  static const _androidSocketBaseUrl = String.fromEnvironment(
    'ANDROID_SOCKET_BASE_URL',
  );
  static const _pushNotificationsEnabled = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: true,
  );
  static const firebaseServicesEnabled = bool.fromEnvironment(
    'ENABLE_FIREBASE_SERVICES',
    defaultValue: true,
  );
  static const _defaultShareBaseUrl = 'https://prokat-bfbec.web.app';
  static const _shareBaseUrl = String.fromEnvironment(
    'SHARE_BASE_URL',
    defaultValue: _defaultShareBaseUrl,
  );
  static const _builtInShareHosts = <String>[
    'prokat-bfbec.web.app',
    'prokat-bfbec.firebaseapp.com',
  ];

  static AppEnvironment get environment => switch (_environmentName) {
    'production' => AppEnvironment.production,
    'local' => AppEnvironment.local,
    _ => throw StateError(
      'Unsupported APP_ENV "$_environmentName". Use "production" or "local".',
    ),
  };

  static bool get isLocal => environment == AppEnvironment.local;

  static String get baseUrl => _resolveEndpoint(
    name: 'API_BASE_URL',
    defaultValue: _apiBaseUrl,
    androidValue: _androidApiBaseUrl,
  );

  /// Socket.IO accepts an HTTP(S) origin and performs the WebSocket upgrade.
  static String get socketUrl {
    final defaultValue = _socketBaseUrl.trim().isEmpty
        ? baseUrl
        : _socketBaseUrl;

    return _resolveEndpoint(
      name: 'SOCKET_BASE_URL',
      defaultValue: defaultValue,
      androidValue: _androidSocketBaseUrl,
    );
  }

  static String get shareBaseUrl => parseShareBaseUrl(_shareBaseUrl);

  static Set<String> get shareTrustedHosts => {
    ..._builtInShareHosts,
    Uri.parse(shareBaseUrl).host.toLowerCase(),
  };

  static String equipmentShareUrl(String equipmentId) {
    final id = equipmentId.trim();
    if (id.isEmpty || id == '.' || id == '..' || id.contains('/')) {
      throw ArgumentError.value(
        equipmentId,
        'equipmentId',
        'must be a single non-empty path segment',
      );
    }
    return '$shareBaseUrl/e/${Uri.encodeComponent(id)}';
  }

  static String parseShareBaseUrl(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    final valid =
        uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.port == 443 &&
        uri.path.isEmpty &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty &&
        !value.endsWith('/');
    if (!valid) {
      throw StateError(
        'SHARE_BASE_URL must be an absolute https URL without a trailing slash, got "$raw".',
      );
    }
    return value;
  }

  static bool get pushNotificationsEnabled {
    if (!firebaseServicesEnabled || !_pushNotificationsEnabled) return false;
    if (kIsWeb) return true;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static String _resolveEndpoint({
    required String name,
    required String defaultValue,
    required String androidValue,
  }) {
    final useAndroidOverride =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        androidValue.trim().isNotEmpty;
    final value = (useAndroidOverride ? androidValue : defaultValue).trim();
    final uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('$name must be an absolute HTTP(S) URL, got "$value".');
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
