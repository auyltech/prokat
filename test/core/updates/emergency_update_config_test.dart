import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/updates/emergency_update_config.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../helpers/fake_emergency_config_client.dart';

class _RecordingFirebaseConfig implements FirebaseRemoteConfig {
  final calls = <String>[];
  Map<String, dynamic>? defaults;
  RemoteConfigSettings? configured;

  @override
  Future<void> ensureInitialized() async {
    calls.add('cache');
  }

  @override
  Future<void> setDefaults(Map<String, dynamic> values) async {
    calls.add('defaults');
    defaults = values;
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {
    calls.add('settings');
    configured = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'FlutterFire adapter hydrates cache and sets safe SDK defaults/settings',
    () async {
      final config = _RecordingFirebaseConfig();
      await FirebaseEmergencyConfigClient(config).prepare();
      expect(config.calls, ['cache', 'defaults', 'settings']);
      expect(config.defaults, emergencyVersionDefaults);
      expect(config.configured!.fetchTimeout, const Duration(seconds: 10));
      expect(config.configured!.minimumFetchInterval, const Duration(hours: 1));
    },
  );
  test('platform key selection and both empty defaults', () {
    expect(
      emergencyVersionKey(TargetPlatform.android),
      'min_supported_version_android',
    );
    expect(
      emergencyVersionKey(TargetPlatform.iOS),
      'min_supported_version_ios',
    );
    expect(emergencyVersionKey(TargetPlatform.windows), isNull);
    expect(emergencyVersionDefaults, {
      'min_supported_version_android': '',
      'min_supported_version_ios': '',
    });
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final cache in ['', '1.2.4+18', 'malformed']) {
      test(
        '$platform reads activated "$cache" immediately and fetches once',
        () async {
          final client = FakeEmergencyConfigClient();
          addTearDown(client.events.close);
          final key = emergencyVersionKey(platform)!;
          client.values[key] = cache;
          final logs = <Object>[];
          final controller = EmergencyMinimumController(
            platform: platform,
            client: client,
            autoStart: false,
            log: logs.add,
          );
          addTearDown(controller.dispose);
          expect(controller.state, cache == '1.2.4+18' ? '1.2.4' : null);
          expect(client.keysRead, [key]);
          expect(client.fetchCalls, 0);
          client.pending[key] = '1.3.0';
          await controller.start();
          await controller.start();
          expect(controller.state, '1.3.0');
          expect(client.fetchCalls, 1);
          expect(client.prepareCalls, 1);
          if (cache == 'malformed') expect(logs, isNotEmpty);
        },
      );
    }
  }

  test(
    'fetch failure keeps the activated cache and never escapes startup',
    () async {
      final client = FakeEmergencyConfigClient()..failFetch = true;
      addTearDown(client.events.close);
      client.values['min_supported_version_android'] = '1.4.0';
      final logs = <Object>[];
      final controller = EmergencyMinimumController(
        platform: TargetPlatform.android,
        client: client,
        autoStart: false,
        log: logs.add,
      );
      addTearDown(controller.dispose);
      await expectLater(controller.start(), completes);
      expect(controller.state, '1.4.0');
      expect(logs.single.toString(), contains('keeping cache'));
    },
  );

  test('missing Firebase safely uses no override', () async {
    final controller = EmergencyMinimumController(
      platform: TargetPlatform.android,
    );
    addTearDown(controller.dispose);
    await expectLater(controller.start(), completes);
    expect(controller.state, isNull);
  });

  test('initialization/cache errors are contained', () async {
    final client = FakeEmergencyConfigClient()
      ..failPrepare = true
      ..failRead = true;
    addTearDown(client.events.close);
    final logs = <Object>[];
    final controller = EmergencyMinimumController(
      platform: TargetPlatform.iOS,
      client: client,
      autoStart: false,
      log: logs.add,
    );
    addTearDown(controller.dispose);
    await expectLater(controller.start(), completes);
    expect(controller.state, isNull);
    expect(logs, isNotEmpty);
  });

  test('a stalled fetch is bounded and preserves cache', () async {
    final client = FakeEmergencyConfigClient()
      ..fetchReply = Completer<bool>().future;
    addTearDown(client.events.close);
    client.values['min_supported_version_android'] = '1.2.4';
    final controller = EmergencyMinimumController(
      platform: TargetPlatform.android,
      client: client,
      autoStart: false,
      timeout: const Duration(milliseconds: 20),
      log: (_) {},
    );
    addTearDown(controller.dispose);
    await expectLater(controller.start(), completes);
    expect(controller.state, '1.2.4');
  });

  test(
    'real-time activation updates, deduplicates state and contains failures',
    () async {
      final client = FakeEmergencyConfigClient();
      addTearDown(client.events.close);
      final logs = <Object>[];
      final controller = EmergencyMinimumController(
        platform: TargetPlatform.android,
        client: client,
        autoStart: false,
        log: logs.add,
      );
      addTearDown(controller.dispose);
      await controller.start();
      final observed = <String?>[];
      final cancel = controller.addListener(
        observed.add,
        fireImmediately: false,
      );
      addTearDown(cancel);
      client.pending['min_supported_version_android'] = '1.2.4';
      client.events.add({'min_supported_version_android'});
      client.events.add({'min_supported_version_android'});
      await pumpEventQueue();
      expect(observed, ['1.2.4']);
      expect(client.fetchCalls, 1);
      client.events.add({'unrelated'});
      await pumpEventQueue();
      expect(client.activationCalls, 2);
      client.failActivate = true;
      client.events.add({'min_supported_version_android'});
      client.events.addError(StateError('stream disconnected'));
      await pumpEventQueue();
      expect(controller.state, '1.2.4');
      expect(logs, hasLength(2));
      client.failActivate = false;
      client.pending['min_supported_version_android'] = 'bad';
      client.events.add({'min_supported_version_android'});
      await pumpEventQueue();
      expect(controller.state, isNull);
      expect(logs.last.toString(), contains('Invalid Remote Config'));
    },
  );
}
