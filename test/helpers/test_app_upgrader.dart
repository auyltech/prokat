import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/core/updates/app_update_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

class TestUpgradeOS extends UpgraderOS {
  TestUpgradeOS([this.platform = UpgraderOSType.android]);
  final UpgraderOSType platform;

  @override
  UpgraderOSType get currentOSType => platform;
}

class TestUpgradeStore extends UpgraderStore {
  TestUpgradeStore({this.availableVersion = '2.0.0', this.mandatory = false});
  final String? availableVersion;
  final bool mandatory;
  final lookups = <({String package, String? country, String? language})>[];

  @override
  Future<UpgraderVersionInfo> getVersionInfo({
    required UpgraderState state,
    required Version installedVersion,
    required String? country,
    required String? language,
  }) async {
    lookups.add((
      package: state.packageInfo!.packageName,
      country: country,
      language: language,
    ));
    return UpgraderVersionInfo(
      installedVersion: installedVersion,
      appStoreVersion: availableVersion == null
          ? null
          : Version.parse(availableVersion!),
      appStoreListingURL: state.upgraderOS.currentOSType == UpgraderOSType.ios
          ? 'https://apps.apple.com/kz/app/prokat/id6817078475'
          : 'https://play.google.com/store/apps/details?id=com.auyltech.prokat',
      minAppVersion: mandatory ? Version.parse('9.0.0') : null,
      isCriticalUpdate: mandatory,
    );
  }
}

class TestAppUpgrader extends SoftAppUpgrader {
  TestAppUpgrader(
    TestUpgradeStore store, {
    UpgraderOSType platform = UpgraderOSType.android,
  }) : super(
         storeController: UpgraderStoreController(
           onAndroid: () => store,
           oniOS: () => store,
         ),
         upgraderOS: TestUpgradeOS(platform),
       );

  int updateCalls = 0;

  @override
  Future<void> sendUserToAppStore() async {
    updateCalls++;
  }
}

void resetUpgradePreferences() {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'PROKAT',
    packageName: 'com.auyltech.prokat',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
}
