import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/core/services/installation_identity_service.dart';

class _MemoryInstallationIdStore implements InstallationIdStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

void main() {
  test(
    'builds mobile identity headers and refreshes App Check token',
    () async {
      var packageLoads = 0;
      var tokenLoads = 0;
      final identity = InstallationIdentityService(
        store: _MemoryInstallationIdStore(),
        isSupportedPlatform: () => true,
      );
      final service = ClientRequestMetadataService(
        installationIdentity: identity,
        platformName: () => 'android',
        loadPackageInfo: () async {
          packageLoads++;
          return PackageInfo(
            appName: 'PROKAT',
            packageName: 'com.auyltech.prokat',
            version: '1.0.7',
            buildNumber: '3',
          );
        },
        loadAppCheckToken: () async {
          tokenLoads++;
          return 'token-$tokenLoads';
        },
      );

      final first = await service.headers();
      final second = await service.headers();

      expect(first['X-Client-Platform'], 'android');
      expect(first['X-App-Version'], '1.0.7');
      expect(first['X-App-Build'], '3');
      expect(first['X-Installation-ID'], isNotEmpty);
      expect(first['X-Firebase-AppCheck'], 'token-1');
      expect(second['X-Installation-ID'], first['X-Installation-ID']);
      expect(second['X-Firebase-AppCheck'], 'token-2');
      expect(packageLoads, 1);
      expect(tokenLoads, 2);
    },
  );

  test('omits App Check header when token acquisition fails', () async {
    final service = ClientRequestMetadataService(
      installationIdentity: InstallationIdentityService(
        store: _MemoryInstallationIdStore(),
        isSupportedPlatform: () => true,
      ),
      platformName: () => 'ios',
      loadPackageInfo: () async => PackageInfo(
        appName: 'PROKAT',
        packageName: 'com.auyltech.prokat',
        version: '1.0.7',
        buildNumber: '3',
      ),
      loadAppCheckToken: () => Future.error(StateError('not configured')),
    );

    final headers = await service.headers();

    expect(headers['X-Client-Platform'], 'ios');
    expect(headers.containsKey('X-Firebase-AppCheck'), isFalse);
  });
}
