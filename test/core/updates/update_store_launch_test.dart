import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/updates/app_update_prompt.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';

import '../../helpers/test_app_upgrader.dart';

class _Launcher extends UrlLauncherPlatform {
  final urls = <String>[];
  bool fail = false;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (fail) throw StateError('store unavailable');
    urls.add(url);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(resetUpgradePreferences);

  for (final platform in [UpgraderOSType.android, UpgraderOSType.ios]) {
    test(
      '$platform has a store update path even without store version info',
      () async {
        final previous = UrlLauncherPlatform.instance;
        final launcher = _Launcher();
        UrlLauncherPlatform.instance = launcher;
        addTearDown(() => UrlLauncherPlatform.instance = previous);
        final store = TestUpgradeStore(availableVersion: null);
        final upgrader = PolicyAppUpgrader(
          storeController: UpgraderStoreController(
            onAndroid: () => store,
            oniOS: () => store,
          ),
          upgraderOS: TestUpgradeOS(platform),
        );
        addTearDown(upgrader.dispose);
        await upgrader.initialize();
        upgrader.updateState(
          upgrader.state.copyWith(versionInfo: UpgraderVersionInfo()),
        );
        expect(upgrader.currentAppStoreListingURL, isNull);
        upgrader.setEmergencyMinimum('1.0.1');
        expect(upgrader.blocked(), isTrue);
        await upgrader.sendUserToAppStore();
        expect(
          launcher.urls.single,
          platform == UpgraderOSType.ios
              ? contains('id6817078475')
              : contains('id=com.auyltech.prokat'),
        );
        launcher.fail = true;
        await expectLater(upgrader.sendUserToAppStore(), completes);
      },
    );
  }
}
