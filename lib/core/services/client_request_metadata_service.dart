import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/services/installation_identity_service.dart';

class ClientRequestMetadataService {
  final InstallationIdentityService installationIdentity;
  final Future<PackageInfo> Function() _loadPackageInfo;
  final Future<String?> Function() _loadAppCheckToken;
  final String Function() _platformName;

  Future<PackageInfo>? _packageInfo;

  ClientRequestMetadataService({
    required this.installationIdentity,
    Future<PackageInfo> Function()? loadPackageInfo,
    Future<String?> Function()? loadAppCheckToken,
    String Function()? platformName,
  }) : _loadPackageInfo = loadPackageInfo ?? PackageInfo.fromPlatform,
       _loadAppCheckToken =
           loadAppCheckToken ?? (() => FirebaseAppCheck.instance.getToken()),
       _platformName = platformName ?? _currentPlatformName;

  Future<Map<String, String>> headers() async {
    final packageInfo = await (_packageInfo ??= _loadPackageInfo());
    final installationId = await installationIdentity.getOrCreate();

    String? appCheckToken;
    try {
      appCheckToken = (await _loadAppCheckToken())?.trim();
      if (appCheckToken?.isEmpty == true) appCheckToken = null;
    } catch (_) {
      // The backend remains the source of truth for App Check enforcement.
      appCheckToken = null;
    }

    return {
      'X-Client-Platform': _platformName(),
      'X-App-Version': packageInfo.version,
      'X-App-Build': packageInfo.buildNumber,
      'X-Installation-ID': ?installationId,
      'X-Firebase-AppCheck': ?appCheckToken,
    };
  }

  static String _currentPlatformName() {
    if (kIsWeb) return 'web';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
