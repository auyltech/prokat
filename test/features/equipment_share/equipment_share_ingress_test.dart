import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_ingress.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_resolver.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';

const _a = 'AbCdEfGhIjKlMnOpQr_-12';
const _b = 'ZyXwVuTsRqPoNmLkJi_-98';
String _key(String value) => Env.isLocal ? 'local_$value' : value;

class _Harness {
  _Harness({Future<ShareResolution> Function(String)? resolver}) {
    ingress = EquipmentShareIngress(
      storage: storage,
      resolve: (id) async {
        calls.add(id);
        return resolver == null
            ? const ShareResolution(ShareResolutionStatus.resolved, 'eq-1')
            : resolver(id);
      },
      isReady: () => ready,
      onAccepted: (open) async => accepted.add(open),
      onFailure: failures.add,
      now: () => now,
    );
  }
  final storage = EquipmentShareStorage();
  final calls = <String>[];
  final accepted = <EquipmentShareOpen>[];
  final failures = <ShareResolutionStatus>[];
  late final EquipmentShareIngress ingress;
  bool ready = true;
  DateTime now = DateTime.utc(2026, 10, 9);

  Future<void> accept(String id, {ShareOpenVia via = ShareOpenVia.appLink}) =>
      ingress.acceptShareId(id, via: via);
}

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _UnavailableStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('storage unavailable');

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('storage unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'optional accepted context storage failure cannot break logout or reads',
    () async {
      final storage = EquipmentShareStorage(storage: _UnavailableStorage());
      await expectLater(storage.clearAcceptedOpen(), completes);
      expect(await storage.readAcceptedOpen(equipmentId: 'eq-1'), isNull);
      await expectLater(storage.clearAcceptedOpen(), completes);
    },
  );

  test('shareId is identity and resolved equipment is routing data', () async {
    final h = _Harness();
    await h.accept(_a);
    final open = h.accepted.single;
    expect(open.link.shareId, _a);
    expect(open.link.equipmentId, 'eq-1');
    expect(open.source, EquipmentShareIngressSource.appLink);
    expect(open.via.wire, 'app_link');
    expect((await h.storage.readOverlaySnapshot()).overlay?.path, '/e/eq-1');
    expect(await h.storage.readPendingOpen(), isNull);
    final retained = await EquipmentShareStorage().readAcceptedOpen(
      equipmentId: 'eq-1',
    );
    expect(retained?.link.shareId, _a);
    expect(await h.storage.readAcceptedOpen(equipmentId: 'eq-2'), isNull);
  });

  test(
    'before auth/bootstrap ready persist without resolving; ready flush once',
    () async {
      final h = _Harness()..ready = false;
      await h.accept(_a);
      expect(h.calls, isEmpty);
      expect((await h.storage.readPendingOpen())?.link.shareId, _a);
      h.ready = true;
      await Future.wait([
        h.ingress.flushPendingUriIfAny(),
        h.ingress.flushPendingUriIfAny(),
        h.ingress.flushPendingUriIfAny(),
      ]);
      expect(h.calls, [_a]);
      expect(h.accepted, hasLength(1));
    },
  );

  test('v2 pending survives process restart including source', () async {
    final first = _Harness()..ready = false;
    await first.accept(_a, via: ShareOpenVia.installReferrer);
    first.ingress.dispose();
    final restarted = _Harness();
    await restarted.ingress.flushPendingUriIfAny();
    expect(restarted.calls, [_a]);
    expect(restarted.accepted.single.link.shareId, _a);
    expect(restarted.accepted.single.via, ShareOpenVia.installReferrer);
  });

  for (final json in [false, true]) {
    test(
      'old persisted ${json ? 'v1 JSON' : 'plain URI'} remains compatible',
      () async {
        const uri = 'https://prokat-bfbec.web.app/e/eq-old?s=$_a';
        FlutterSecureStorage.setMockInitialValues({
          _key('equipment_share_pending_uri'): json
              ? jsonEncode({
                  'v': 1,
                  'uri': uri,
                  'via': 'app_link',
                  'firstShareBootstrapRun': true,
                })
              : uri,
        });
        final h = _Harness();
        await h.ingress.flushPendingUriIfAny();
        expect(h.calls, isEmpty);
        expect(h.accepted.single.link.equipmentId, 'eq-old');
        expect(h.accepted.single.link.shareId, _a);
        expect(
          h.accepted.single.source,
          EquipmentShareIngressSource.legacyLink,
        );
      },
    );
  }

  test(
    'duplicate initial/runtime delivery does not resolve or accept twice',
    () async {
      final h = _Harness();
      await h.accept(_a);
      await h.accept(_a);
      await h.ingress.flushPendingUriIfAny();
      expect(h.calls, [_a]);
      expect(h.accepted, hasLength(1));
    },
  );

  test(
    'duplicate while resolving is ignored even beyond debounce window',
    () async {
      final result = Completer<ShareResolution>();
      final h = _Harness(resolver: (_) => result.future);
      final first = h.accept(_a);
      await _until(() => h.calls.isNotEmpty);
      h.now = h.now.add(const Duration(seconds: 5));
      await h.accept(_a);
      result.complete(
        const ShareResolution(ShareResolutionStatus.resolved, 'eq-a'),
      );
      await first;
      expect(h.calls, [_a]);
      expect(h.accepted, hasLength(1));
    },
  );

  for (final finishOldFirst in [false, true]) {
    test(
      'latest wins with old resolver finishing ${finishOldFirst ? 'first' : 'last'}',
      () async {
        final a = Completer<ShareResolution>();
        final b = Completer<ShareResolution>();
        final h = _Harness(resolver: (id) => id == _a ? a.future : b.future);
        final old = h.accept(_a);
        await _until(() => h.calls.length == 1);
        final newer = h.accept(_b);
        await _until(() => h.calls.length == 2);
        if (finishOldFirst) {
          a.complete(
            const ShareResolution(ShareResolutionStatus.resolved, 'eq-a'),
          );
          await old;
          expect(h.accepted, isEmpty);
        }
        b.complete(
          const ShareResolution(ShareResolutionStatus.resolved, 'eq-b'),
        );
        await newer;
        if (!finishOldFirst) {
          a.complete(
            const ShareResolution(ShareResolutionStatus.resolved, 'eq-a'),
          );
          await old;
        }
        expect(h.accepted.single.link.shareId, _b);
        expect(
          (await h.storage.readOverlaySnapshot()).overlay?.path,
          '/e/eq-b',
        );
        expect(
          (await h.storage.readAcceptedOpen(equipmentId: 'eq-b'))?.link.shareId,
          _b,
        );
        expect(await h.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
      },
    );
  }

  for (final failure in [
    ShareResolutionStatus.unavailable,
    ShareResolutionStatus.invalid,
  ]) {
    test('$failure clears pending and never opens a card', () async {
      final h = _Harness(resolver: (_) async => ShareResolution(failure));
      await h.accept(_a);
      await h.ingress.flushPendingUriIfAny();
      expect(h.failures, [failure]);
      expect(h.accepted, isEmpty);
      expect(await h.storage.readPendingOpen(), isNull);
      expect((await h.storage.readOverlaySnapshot()).overlay, isNull);
    });
  }

  test('temporary failure retains context; no automatic infinite retries; explicit retry', () async {
    var available = false;
    final h = _Harness(
      resolver: (_) async => available
          ? const ShareResolution(ShareResolutionStatus.resolved, 'eq-1')
          : const ShareResolution(ShareResolutionStatus.temporary),
    );
    await h.accept(_a);
    for (var i = 0; i < 5; i++) {
      await h.ingress.flushPendingUriIfAny();
    }
    expect(h.calls, [_a]);
    expect(h.failures, [ShareResolutionStatus.temporary]);
    expect((await h.storage.readPendingOpen())?.link.shareId, _a);
    available = true;
    await h.ingress.flushPendingUriIfAny(retry: true);
    expect(h.calls, [_a, _a]);
    expect(h.accepted.single.link.shareId, _a);
  });

  test(
    'retry by opening the same link again is allowed after debounce',
    () async {
      final h = _Harness(
        resolver: (_) async =>
            const ShareResolution(ShareResolutionStatus.temporary),
      );
      await h.accept(_a);
      h.now = h.now.add(const Duration(seconds: 3));
      await h.accept(_a);
      expect(h.calls, [_a, _a]);
    },
  );

  test('disposed ingress cannot accept stale resolver results', () async {
    final result = Completer<ShareResolution>();
    final h = _Harness(resolver: (_) => result.future);
    final incoming = h.accept(_a);
    await _until(() => h.calls.isNotEmpty);
    h.ingress.dispose();
    result.complete(
      const ShareResolution(ShareResolutionStatus.resolved, 'eq-1'),
    );
    await incoming;
    expect(h.accepted, isEmpty);
    expect((await h.storage.readOverlaySnapshot()).overlay, isNull);
  });

  test('logout clearing pending invalidates an in-flight result', () async {
    final result = Completer<ShareResolution>();
    final h = _Harness(resolver: (_) => result.future);
    final incoming = h.accept(_a);
    await _until(() => h.calls.isNotEmpty);
    await h.storage.clearPendingUri();
    await h.storage.clearAcceptedOpen();
    result.complete(
      const ShareResolution(ShareResolutionStatus.resolved, 'eq-1'),
    );
    await incoming;
    expect(h.accepted, isEmpty);
    expect(await h.storage.readAcceptedOpen(equipmentId: 'eq-1'), isNull);
  });

  test(
    'future deferred_install uses the same resolver/pending/overlay',
    () async {
      final h = _Harness()..ready = false;
      await h.accept(_a, via: ShareOpenVia.deferredInstall);
      h.ready = true;
      await h.ingress.flushPendingUriIfAny();
      expect(h.calls, [_a]);
      expect(
        h.accepted.single.source,
        EquipmentShareIngressSource.deferredInstall,
      );
      expect(h.accepted.single.link.shareId, _a);
      expect(h.accepted.single.via.api, isNull);
      expect((await h.storage.readOverlaySnapshot()).overlay?.path, '/e/eq-1');
    },
  );

  test(
    'untrusted or malformed URI cannot replace a valid pending context',
    () async {
      final h = _Harness()..ready = false;
      await h.accept(_a);
      expect(
        await h.ingress.acceptUri(
          Uri.parse('https://evil.test/e/$_b'),
          via: ShareOpenVia.appLink,
          firstShareBootstrapRun: false,
        ),
        isFalse,
      );
      expect((await h.storage.readPendingOpen())?.link.shareId, _a);
    },
  );

  test(
    'resolved v2 context round trips without changing its share identity',
    () {
      final open = EquipmentShareOpen(
        link: EquipmentShareLink.fromShareId(_a),
        via: ShareOpenVia.appLink,
        firstShareBootstrapRun: true,
      ).resolved('eq-1');
      final restored = EquipmentShareOpen.tryParse(jsonEncode(open.toJson()))!;
      expect(restored.link.equipmentId, 'eq-1');
      expect(restored.link.shareId, _a);
      expect(
        restored.link.uri.toString(),
        'https://open.prokat.auyltech.kz/e/$_a',
      );
      expect(restored.firstShareBootstrapRun, isTrue);
      expect(open.toJson()['v'], 2);
    },
  );
}
