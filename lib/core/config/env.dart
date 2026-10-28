import 'package:flutter/foundation.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';

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
  static const _analyticsForceCollection = bool.fromEnvironment(
    'ANALYTICS_FORCE_COLLECTION',
  );
  static const _analyticsEnabled = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
  static const _crashReportingEnabled = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: true,
  );
  static const _shareAnalyticsEnabled = bool.fromEnvironment(
    'ENABLE_SHARE_ANALYTICS',
    defaultValue: true,
  );
  static const appOpenBaseUrl = String.fromEnvironment(
    'APP_OPEN_BASE_URL',
    defaultValue: 'https://open.prokat.auyltech.kz',
  );

  static bool get shareAnalyticsEnabled => !isLocal && _shareAnalyticsEnabled;
  static bool get crashReportingEnabled =>
      !isLocal && _crashReportingEnabled && !kDebugMode;
  static const _defaultShareBaseUrl = 'https://prokat.auyltech.kz';
  static const _shareBaseUrl = String.fromEnvironment(
    'SHARE_BASE_URL',
    defaultValue: _defaultShareBaseUrl,
  );

  /// Legacy inbound hosts only; never used to generate outbound shares.
  static const shareTrustedHosts = <String>{
    'prokat-bfbec.web.app',
    'prokat-bfbec.firebaseapp.com',
  };
  static Uri get legacyShareBaseUri => Uri.https(shareTrustedHosts.first);

  static AppEnvironment get environment => switch (_environmentName) {
    'production' => AppEnvironment.production,
    'local' => AppEnvironment.local,
    _ => throw StateError(
      'Unsupported APP_ENV "$_environmentName". Use "production" or "local".',
    ),
  };

  static bool get isLocal => environment == AppEnvironment.local;

  static bool get analyticsCollectionEnabled =>
      firebaseServicesEnabled &&
      !isLocal &&
      _analyticsEnabled &&
      ((environment == AppEnvironment.production && !kDebugMode) ||
          _analyticsForceCollection);

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

  // Production is canonical even when an old build config supplies a legacy
  // SHARE_BASE_URL or SHARE_LINK_MODE. Local replica URLs stay loopback-only.
  static String get shareBaseUrl =>
      isLocal ? parseShareBaseUrl(_shareBaseUrl) : _defaultShareBaseUrl;

  static String publicEquipmentShareUrl(String shareId) {
    if (!isValidShareId(shareId)) {
      throw ArgumentError.value(
        shareId,
        'shareId',
        'must be 22 unpadded base64url characters',
      );
    }
    return '$shareBaseUrl/e/$shareId';
  }

  static String parseShareBaseUrl(String raw) {
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    final valid =
        uri != null &&
        ((uri.scheme == 'https' &&
                uri.host == 'prokat.auyltech.kz' &&
                uri.port == 443) ||
            (isLocal &&
                const {'http', 'https'}.contains(uri.scheme) &&
                const {'localhost', '127.0.0.1', '::1'}.contains(uri.host))) &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        (isLocal || uri.port == 443) &&
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
