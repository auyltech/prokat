import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_share/equipment_share_ingress.dart';
import 'package:prokat/features/equipment_share/equipment_share_first_touch.dart';
import 'package:prokat/features/equipment_share/equipment_share_booking_intent.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_resolver.dart';
import 'package:prokat/features/equipment_share/equipment_share_state.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';
import 'package:prokat/features/locations/models/location_model.dart';

const _a = 'AbCdEfGhIjKlMnOpQr_-12';
const _b = 'ZyXwVuTsRqPoNmLkJi_-98';
final _stateKey = shareStorageKey('equipment_share_state');
final _epochKey = shareStorageKey('equipment_share_privacy_epoch');
final _at = DateTime.utc(2026, 10, 9);
String _id(int n) =>
    '${n.toString().padLeft(8, '0')}-0000-4000-8000-000000000001';

class _Disk {
  final values = <String, String>{};
  int ids = 0;
}

// A dead native client cannot perform the old process's catch/finally writes.
class _NativeStorage extends FlutterSecureStorage {
  _NativeStorage(this.disk);
  final _Disk disk;
  bool dead = false;
  int stateWrites = 0;
  int? crashWrite;
  bool crashAfterCommit = false;
  bool Function(String operation, String key, String? value)? fail;
  Completer<void>? writeGate;
  String? gateKey;
  final enteredWrite = Completer<void>();

  void _check(String op, String key, [String? value]) {
    if (dead || (fail?.call(op, key, value) ?? false)) {
      throw StateError('simulated storage interruption');
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check('read', key);
    return disk.values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check('write', key, value);
    if (key == (gateKey ?? _stateKey) && writeGate != null) {
      final gate = writeGate!;
      writeGate = null;
      if (!enteredWrite.isCompleted) enteredWrite.complete();
      await gate.future;
      _check('write', key, value);
    }
    if (key == _stateKey) {
      stateWrites++;
      if (stateWrites == crashWrite && !crashAfterCommit) {
        dead = true;
        _check('write', key);
      }
    }
    if (value == null) {
      disk.values.remove(key);
    } else {
      disk.values[key] = value;
    }
    if (key == _stateKey && stateWrites == crashWrite && crashAfterCommit) {
      dead = true;
      _check('write', key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check('delete', key);
    disk.values.remove(key);
  }
}

class _Process {
  _Process(this.disk, {Future<ShareResolution> Function(String)? resolver}) {
    native = _NativeStorage(disk);
    storage = EquipmentShareStorage(
      storage: native,
      newIntentId: () => _id(++disk.ids),
    );
    ingress = EquipmentShareIngress(
      storage: storage,
      resolve: (id) async {
        calls.add(id);
        return resolver == null
            ? ShareResolution(
                ShareResolutionStatus.resolved,
                id == _a ? 'eq-a' : 'eq-b',
              )
            : resolver(id);
      },
      isReady: () => ready,
      onAccepted: (open) async => accepted.add(open),
      onFailure: failures.add,
      now: () => now,
    );
  }
  final _Disk disk;
  late final _NativeStorage native;
  late final EquipmentShareStorage storage;
  late final EquipmentShareIngress ingress;
  final calls = <String>[];
  final accepted = <EquipmentShareOpen>[];
  final failures = <ShareResolutionStatus>[];
  bool ready = true;
  DateTime now = _at;
  Future<void> accept(String id, {ShareOpenVia via = ShareOpenVia.appLink}) =>
      ingress.acceptShareId(id, via: via);
  Future<void> recover() => ingress.flushPendingUriIfAny();
  _Process restart() {
    ingress.dispose();
    native.dead = true;
    return _Process(disk)..now = now;
  }
}

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

EquipmentShareBookingIntent _form(String equipment) =>
    EquipmentShareBookingIntent(
      userId: null,
      equipmentId: equipment,
      priceEntryId: 'price-1',
      priceSnapshot: 15000,
      comment: 'guest form',
      scheduleMode: 'scheduled',
      bookedOn: _at,
      bookedAt: _at,
      address: LocationModel(
        service: 'ADDRESS',
        street: 'Test',
        city: 'Atyrau',
        country: 'Kazakhstan',
        latitude: 47.1,
        longitude: 51.9,
      ),
    );

Future<void> _expectAccepted(_Process p, String share, String equipment) async {
  final accepted = await p.storage.readAcceptedOpen(equipmentId: equipment);
  expect(accepted?.link.shareId, share);
  expect(accepted?.link.equipmentId, equipment);
  expect(isShareIntentId(accepted!.clientEventId!), isTrue);
  expect(
    (await p.storage.readOverlaySnapshot()).overlay?.path,
    '/e/$equipment',
  );
  expect(await p.storage.readPendingOpen(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first-touch memory revocation rejects old data after total outage heals before share-store read', () async {
    final p = _Process(_Disk());
    final touch = EquipmentShareFirstTouchStore(
      storage: p.native,
      now: () => _at,
    );
    await touch.saveIfEmpty(
      FirstTouchAttribution(
        shareId: _a,
        equipmentId: 'eq-a',
        via: ShareOpenVia.appLink,
        firstShareBootstrapRun: false,
        receivedAt: _at,
      ),
    );
    p.native.fail = (_, _, _) => true;
    await p.storage.clearForLogout();
    await touch.clear();
    p.native.fail = null;
    expect(await touch.readValid(), isNull);
    expect(await touch.readValid(), isNull);
  });

  test(
    'logout fence rejects new ingress until old account cleanup finishes',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      await p.storage.clearForLogout(holdFence: true);
      await p.accept(_b);
      expect(p.accepted, hasLength(1));
      expect(await p.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
      p.storage.finishLogout();
      p.now = p.now.add(const Duration(seconds: 3));
      await p.accept(_b);
      await _expectAccepted(p, _b, 'eq-b');
    },
  );

  test(
    'delayed old address/form writer cannot replace B even without afterAuth',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      await p.accept(_b);
      await expectLater(
        p.storage.saveBookingIntent(_form('eq-a')),
        throwsStateError,
      );
      await _expectAccepted(p, _b, 'eq-b');
    },
  );

  test(
    'legacy form and accepted cannot be correlated by equipment alone',
    () async {
      final disk = _Disk();
      final open = EquipmentShareOpen(
        link: EquipmentShareLink.fromShareId(_a).withEquipmentId('eq-a'),
        via: ShareOpenVia.appLink,
        firstShareBootstrapRun: false,
      );
      disk.values[shareStorageKey('equipment_share_accepted_open')] =
          jsonEncode(open.toJson());
      disk.values[shareStorageKey('equipment_share_booking_intent')] =
          jsonEncode(_form('eq-a').toJson());
      final p = _Process(disk);
      expect(await p.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
      expect((await p.storage.readBookingIntent())?.equipmentId, 'eq-a');
    },
  );

  for (final after in [false, true]) {
    test(
      'Install Referrer crash ${after ? 'after' : 'before'} pending commit cannot consume without intent',
      () async {
        final p = _Process(_Disk())..ready = false;
        p.native.crashWrite = 1;
        p.native.crashAfterCommit = after;
        await p.accept(_a, via: ShareOpenVia.installReferrer);
        final next = p.restart();
        expect(await next.storage.wasInstallReferrerChecked(), after);
        if (after) {
          await next.recover();
          await _expectAccepted(next, _a, 'eq-a');
          expect(next.accepted.single.via, ShareOpenVia.installReferrer);
        } else {
          await next.accept(_a, via: ShareOpenVia.installReferrer);
          await _expectAccepted(next, _a, 'eq-a');
        }
      },
    );
  }

  test('consumed referrer survives newer share and logout without depending on separate flag write', () async {
    final p = _Process(_Disk());
    await p.accept(_a, via: ShareOpenVia.installReferrer);
    await p.accept(_b);
    final next = p.restart();
    expect(await next.storage.wasInstallReferrerChecked(), isTrue);
    await next.storage.clearForLogout();
    final again = next.restart();
    expect(await again.storage.wasInstallReferrerChecked(), isTrue);
    expect(await again.storage.hasRecoverableIntent(), isFalse);
  });

  test(
    'local OPENED acknowledgement failure releases claim for explicit retry',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      final id = p.accepted.single.clientEventId!;
      final claim = await p.storage.claimOpenReceipt(id);
      p.native.fail = (op, key, _) => op == 'write' && key == _stateKey;
      await expectLater(
        p.storage.finishOpenReceipt(id, claim!.account, delivered: true),
        throwsStateError,
      );
      p.native.fail = null;
      expect((await p.storage.claimOpenReceipt(id))?.analytics, isFalse);
    },
  );

  test(
    'corrupt legacy accepted context does not crash normal startup',
    () async {
      final disk = _Disk();
      disk.values[shareStorageKey('equipment_share_accepted_open')] = '{broken';
      final p = _Process(disk);
      await p.recover();
      expect(p.accepted, isEmpty);
      expect(
        disk.values.containsKey(
          shareStorageKey('equipment_share_accepted_open'),
        ),
        isFalse,
      );
    },
  );

  for (final after in [false, true]) {
    test(
      'OTP continuation crash ${after ? 'after' : 'before'} single form/overlay commit has no partial pair',
      () async {
        final p = _Process(_Disk());
        await p.accept(_a);
        await p.storage.clearOverlay();
        p.native.crashWrite = p.native.stateWrites + 1;
        p.native.crashAfterCommit = after;
        await expectLater(
          p.storage.saveBookingIntent(_form('eq-a'), afterAuth: true),
          throwsStateError,
        );
        final next = p.restart();
        final form = await next.storage.readBookingIntent();
        final overlay = (await next.storage.readOverlaySnapshot()).overlay;
        expect(form != null, after);
        expect(overlay?.afterAuth, after ? isTrue : isNull);
        expect(
          (await next.storage.readAcceptedOpen(equipmentId: 'eq-a'))
              ?.link
              .shareId,
          _a,
        );
        if (after) {
          expect(
            decideShareIntent(
              intent: form,
              equipmentId: 'eq-a',
              currentUserId: 'newly-logged-in',
            ),
            ShareIntentDecision.apply,
          );
        }
      },
    );
  }

  test(
    'old guest form cannot replace newer authoritative pending share',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      p.ready = false;
      await p.accept(_b);
      await expectLater(
        p.storage.saveBookingIntent(_form('eq-a'), afterAuth: true),
        throwsStateError,
      );
      final next = p.restart();
      await next.recover();
      await _expectAccepted(next, _b, 'eq-b');
      expect(await next.storage.readBookingIntent(), isNull);
    },
  );

  test(
    'logout removes guest form and afterAuth overlay for next account',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      await p.storage.saveBookingIntent(_form('eq-a'), afterAuth: true);
      await p.storage.clearForLogout();
      final next = p.restart();
      expect(await next.storage.readBookingIntent(), isNull);
      expect((await next.storage.readOverlaySnapshot()).overlay, isNull);
    },
  );

  test(
    'logout during delayed first-touch write cannot leak to next account',
    () async {
      final p = _Process(_Disk());
      final touch = EquipmentShareFirstTouchStore(
        storage: p.native,
        now: () => _at,
      );
      final gate = Completer<void>();
      p.native.gateKey = shareStorageKey('equipment_share_first_touch');
      p.native.writeGate = gate;
      final saving = touch.saveIfEmpty(
        FirstTouchAttribution(
          shareId: _a,
          equipmentId: 'eq-a',
          via: ShareOpenVia.appLink,
          firstShareBootstrapRun: false,
          receivedAt: _at,
        ),
      );
      await p.native.enteredWrite.future;
      await p.storage.clearForLogout();
      final clearing = touch.clear();
      gate.complete();
      await Future.wait([saving, clearing]);
      final next = p.restart();
      expect(
        await EquipmentShareFirstTouchStore(
          storage: next.native,
          now: () => _at,
        ).readValid(),
        isNull,
      );
    },
  );

  test(
    'corrupt revocation marker is rotated and stale accepted state quarantined',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      p.disk.values[_epochKey] = 'broken';
      final next = p.restart();
      await next.recover();
      expect(next.accepted, isEmpty);
      expect(isSharePrivacyEpoch(p.disk.values[_epochKey]!), isTrue);
      expect(await next.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
    },
  );

  test('logout epoch rejects old first-touch even when its delete and overwrite both fail', () async {
    final p = _Process(_Disk());
    final firstTouch = EquipmentShareFirstTouchStore(
      storage: p.native,
      now: () => _at,
    );
    await firstTouch.saveIfEmpty(
      FirstTouchAttribution(
        shareId: _a,
        equipmentId: 'eq-a',
        via: ShareOpenVia.appLink,
        firstShareBootstrapRun: false,
        receivedAt: _at,
      ),
    );
    final key = shareStorageKey('equipment_share_first_touch');
    p.native.fail = (op, target, _) =>
        (op == 'delete' || op == 'write') && target == key;
    await p.storage.clearForLogout();
    await firstTouch.clear();
    final next = p.restart();
    final newFirstTouch = EquipmentShareFirstTouchStore(
      storage: next.native,
      now: () => _at,
    );
    expect(await newFirstTouch.readValid(), isNull);
    expect(p.disk.values[key], isNull);
  });

  test(
    'logout memory fences remain usable even if every durable operation fails',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      final id = p.accepted.single.clientEventId!;
      final claim = await p.storage.claimOpenReceipt(id);
      p.native.fail = (_, _, _) => true;
      await expectLater(p.storage.clearForLogout(), completes);
      expect(p.storage.receiptIsCurrent(id, claim!.account), isFalse);
      expect(await p.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
      p.native.fail = null;
      await p.storage.clearForLogout();
      final next = p.restart();
      expect(await next.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
    },
  );

  for (final broken in ['state', 'epoch']) {
    test(
      'second logout $broken failure selects newest revocation, not previous account epoch',
      () async {
        final p = _Process(_Disk());
        await p.storage.clearForLogout();
        await p.accept(_a);
        final touch = EquipmentShareFirstTouchStore(
          storage: p.native,
          now: () => _at,
        );
        await touch.saveIfEmpty(
          FirstTouchAttribution(
            shareId: _a,
            equipmentId: 'eq-a',
            via: ShareOpenVia.appLink,
            firstShareBootstrapRun: false,
            receivedAt: _at,
          ),
        );
        p.native.fail = (op, key, _) =>
            (op == 'write' || op == 'delete') &&
            (key == (broken == 'state' ? _stateKey : _epochKey) ||
                key == shareStorageKey('equipment_share_first_touch'));
        await p.storage.clearForLogout();
        await touch.clear();
        final next = p.restart();
        await next.recover();
        expect(
          await next.storage.readAcceptedOpen(equipmentId: 'eq-a'),
          isNull,
        );
        expect(
          await EquipmentShareFirstTouchStore(
            storage: next.native,
            now: () => _at,
          ).readValid(),
          isNull,
        );
      },
    );
  }

  for (final cut in [
    (
      name: '1 before pending persistence',
      write: 1,
      after: false,
      resolved: false,
    ),
    (
      name: '2 after pending persistence',
      write: 1,
      after: true,
      resolved: false,
    ),
    (
      name: '3 resolver success before accepted persistence',
      write: 2,
      after: false,
      resolved: false,
    ),
    (name: '4 accepted context commit', write: 2, after: true, resolved: true),
    (
      name: '5 overlay commit before old pending cleanup',
      write: 2,
      after: true,
      resolved: true,
    ),
    (
      name: '6 pending cleanup (same atomic replacement)',
      write: 2,
      after: true,
      resolved: true,
    ),
  ]) {
    test('crash cut ${cut.name} reconstructs new process', () async {
      final old = _Process(_Disk());
      old.native.crashWrite = cut.write;
      old.native.crashAfterCommit = cut.after;
      await old.accept(_a);
      final next = old.restart();
      await next.recover();
      if (cut.write == 1 && !cut.after) {
        expect(next.calls, isEmpty);
        expect(next.accepted, isEmpty);
        expect(await next.storage.hasRecoverableIntent(), isFalse);
      } else {
        await _expectAccepted(next, _a, 'eq-a');
        expect(next.calls, cut.resolved ? isEmpty : [_a]);
        final writes = next.native.stateWrites;
        await next.recover();
        expect(next.accepted, hasLength(1));
        expect(next.native.stateWrites, writes);
      }
    });
  }

  for (final cut in [
    '7 during overlay claim',
    '8 before router push',
    '9 after navigation decision before route observation',
  ]) {
    test(
      'crash cut $cut retains navigation instruction and attribution',
      () async {
        final old = _Process(_Disk());
        await old.accept(_a);
        final snap = await old.storage.readOverlaySnapshot();
        expect(await old.storage.claimOverlayIfUnchanged(snap.token), isTrue);
        expect(await old.storage.claimOverlayIfUnchanged(snap.token), isFalse);
        final next = old.restart();
        await next.recover();
        await _expectAccepted(next, _a, 'eq-a');
        final resumed = await next.storage.readOverlaySnapshot();
        expect(
          await next.storage.claimOverlayIfUnchanged(resumed.token),
          isTrue,
        );
        expect(
          await next.storage.clearOverlayIfUnchanged(resumed.token),
          isTrue,
        );
        final again = next.restart();
        await again.recover();
        expect((await again.storage.readOverlaySnapshot()).overlay, isNull);
        expect(
          (await again.storage.readAcceptedOpen(equipmentId: 'eq-a'))
              ?.link
              .shareId,
          _a,
        );
        expect(again.calls, isEmpty);
      },
    );
  }

  test(
    'resolver A completes after durable B and cannot resurrect on restart',
    () async {
      final a = Completer<ShareResolution>();
      final p = _Process(
        _Disk(),
        resolver: (id) => id == _a
            ? a.future
            : Future.value(
                const ShareResolution(ShareResolutionStatus.resolved, 'eq-b'),
              ),
      );
      final old = p.accept(_a);
      await _until(() => p.calls.isNotEmpty);
      await p.accept(_b);
      a.complete(const ShareResolution(ShareResolutionStatus.resolved, 'eq-a'));
      await old;
      final next = p.restart();
      await next.recover();
      await _expectAccepted(next, _b, 'eq-b');
      expect(await next.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
      expect(next.calls, isEmpty);
    },
  );

  test(
    'delayed native write A is serialized before B and never overwrites B',
    () async {
      final p = _Process(_Disk());
      final gate = Completer<void>();
      p.native.writeGate = gate;
      final a = p.accept(_a);
      await p.native.enteredWrite.future;
      final b = p.accept(_b);
      gate.complete();
      await Future.wait([a, b]);
      expect(p.accepted.single.link.shareId, _b);
      final next = p.restart();
      await next.recover();
      await _expectAccepted(next, _b, 'eq-b');
    },
  );

  test('stale legacy durable A cannot overwrite canonical B', () async {
    final p = _Process(_Disk());
    await p.accept(_b);
    p.disk.values[shareStorageKey('equipment_share_pending_uri')] =
        'https://prokat-bfbec.web.app/e/eq-a?s=$_a';
    final next = p.restart();
    await next.recover();
    await _expectAccepted(next, _b, 'eq-b');
  });

  test(
    'logout during resolver fences its result before remote logout',
    () async {
      final result = Completer<ShareResolution>();
      final p = _Process(_Disk(), resolver: (_) => result.future);
      final run = p.accept(_a);
      await _until(() => p.calls.isNotEmpty);
      await p.storage.clearForLogout();
      result.complete(
        const ShareResolution(ShareResolutionStatus.resolved, 'eq-a'),
      );
      await run;
      final next = p.restart();
      await next.recover();
      expect(next.accepted, isEmpty);
      expect(await next.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
    },
  );

  test(
    'logout during delayed native write puts revocation after old write',
    () async {
      final p = _Process(_Disk());
      final gate = Completer<void>();
      p.native.writeGate = gate;
      final run = p.accept(_a);
      await p.native.enteredWrite.future;
      final clearing = p.storage.clearForLogout();
      gate.complete();
      await Future.wait([run, clearing]);
      final next = p.restart();
      await next.recover();
      expect(next.calls, isEmpty);
      expect(next.accepted, isEmpty);
      expect(await next.storage.hasRecoverableIntent(), isFalse);
    },
  );

  for (final mode in ['concurrent', 'within window', 'after restart']) {
    test(
      'same share duplicate $mode retains one logical clientEventId',
      () async {
        final p = _Process(_Disk());
        if (mode == 'concurrent') {
          await Future.wait([p.accept(_a), p.accept(_a)]);
        } else {
          await p.accept(_a);
          await p.accept(_a);
        }
        expect(p.calls, [_a]);
        expect(p.accepted, hasLength(1));
        final id = p.accepted.single.clientEventId;
        final next = p.restart();
        await next.accept(_a);
        expect(next.calls, isEmpty);
        expect(
          (await next.storage.readAcceptedOpen(equipmentId: 'eq-a'))
              ?.clientEventId,
          id,
        );
      },
    );
  }

  test('intentional same-share open after window creates a fresh intent, not permanent dedup', () async {
    final p = _Process(_Disk());
    await p.accept(_a);
    final first = p.accepted.single.clientEventId;
    await p.storage.clearOverlay();
    p.now = p.now.add(const Duration(seconds: 3));
    await p.accept(_a);
    expect(p.calls, [_a, _a]);
    expect(p.accepted.last.clientEventId, isNot(first));
  });

  test(
    'two shareIds for same equipment remain different attribution intents',
    () async {
      final p = _Process(
        _Disk(),
        resolver: (_) async =>
            const ShareResolution(ShareResolutionStatus.resolved, 'eq-same'),
      );
      await p.accept(_a);
      await p.accept(_b);
      expect(p.accepted, hasLength(2));
      expect(p.accepted[0].clientEventId, isNot(p.accepted[1].clientEventId));
      await _expectAccepted(p, _b, 'eq-same');
    },
  );

  for (final scenario in [
    'unauthenticated then login',
    'OTP crash/restart',
    'login succeeded before navigation',
  ]) {
    test(
      '$scenario retains pending share and resolves once when ready',
      () async {
        final p = _Process(_Disk())..ready = false;
        await p.accept(_a);
        expect(p.calls, isEmpty);
        final next = p.restart()..ready = false;
        await next.recover();
        expect(next.calls, isEmpty);
        expect((await next.storage.readPendingOpen())?.link.shareId, _a);
        next.ready = true;
        await next.recover();
        await _expectAccepted(next, _a, 'eq-a');
        await next.recover();
        expect(next.calls, [_a]);
      },
    );
  }

  test(
    'accepted share logout restart cannot become next account attribution',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      await p.storage.clearForLogout();
      final next = p.restart();
      await next.recover();
      expect(await next.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
      expect(await next.storage.readOpenReceipt(), isNull);
      expect((await next.storage.readOverlaySnapshot()).overlay, isNull);
      await next.accept(_b);
      await _expectAccepted(next, _b, 'eq-b');
    },
  );

  for (final corrupt in [
    'malformed JSON',
    'truncated JSON',
    'unsupported version',
    'invalid shareId',
    'invalid equipmentId',
    'unsupported source',
    'missing fields',
    'mismatched eventId',
    'mismatched overlay',
  ]) {
    test(
      'corrupt envelope $corrupt is cleared without navigation or attribution',
      () async {
        final p = _Process(_Disk());
        await p.accept(_a);
        final map =
            jsonDecode(p.disk.values[_stateKey]!) as Map<String, dynamic>;
        switch (corrupt) {
          case 'malformed JSON':
            p.disk.values[_stateKey] = 'not JSON';
          case 'truncated JSON':
            p.disk.values[_stateKey] = '{"v":3,';
          case 'unsupported version':
            map['v'] = 99;
          case 'invalid shareId':
            (map['open'] as Map)['uri'] =
                'https://open.prokat.auyltech.kz/e/invalid';
          case 'invalid equipmentId':
            (map['open'] as Map)['resolvedEquipmentId'] = '../private';
          case 'unsupported source':
            (map['open'] as Map)['via'] = 'unknown';
          case 'missing fields':
            map.remove('receivedAt');
          case 'mismatched eventId':
            map['intentId'] = _id(99);
          case 'mismatched overlay':
            (map['overlay'] as Map)['path'] = '/e/eq-b';
        }
        if (!corrupt.contains('JSON')) {
          p.disk.values[_stateKey] = jsonEncode(map);
        }
        final next = p.restart();
        await next.recover();
        expect(next.accepted, isEmpty);
        expect(next.calls, isEmpty);
        expect(await next.storage.hasRecoverableIntent(), isFalse);
        expect(
          await next.storage.readAcceptedOpen(equipmentId: 'eq-a'),
          isNull,
        );
        expect(
          (jsonDecode(next.disk.values[_stateKey]!) as Map)['open'],
          isNull,
        );
      },
    );
  }

  for (final legacy in [
    '{broken',
    jsonEncode({'v': 99}),
    jsonEncode({'v': 2, 'shareId': 'bad', 'via': 'app_link'}),
  ]) {
    test(
      'malformed legacy pending $legacy cannot resurrect accepted context',
      () async {
        final disk = _Disk();
        disk.values[shareStorageKey('equipment_share_pending_uri')] = legacy;
        final p = _Process(disk);
        await p.recover();
        expect(p.accepted, isEmpty);
        expect(await p.storage.hasRecoverableIntent(), isFalse);
        expect(
          disk.values.containsKey(
            shareStorageKey('equipment_share_pending_uri'),
          ),
          isFalse,
        );
      },
    );
  }

  test(
    'legacy accepted A plus uncorrelated overlay B never cross-pair',
    () async {
      final disk = _Disk();
      final old = EquipmentShareOpen(
        link: EquipmentShareLink.fromShareId(_a).withEquipmentId('eq-a'),
        via: ShareOpenVia.appLink,
        firstShareBootstrapRun: false,
      );
      disk.values[shareStorageKey('equipment_share_accepted_open')] =
          jsonEncode(old.toJson());
      disk.values[shareStorageKey('equipment_share_overlay')] = jsonEncode({
        'path': '/e/eq-b',
      });
      final p = _Process(disk);
      await p.recover();
      expect((await p.storage.readOverlaySnapshot()).overlay?.path, '/e/eq-b');
      expect(await p.storage.readAcceptedOpen(equipmentId: 'eq-a'), isNull);
      expect(await p.storage.readAcceptedOpen(equipmentId: 'eq-b'), isNull);
    },
  );

  test(
    'storage read failure is temporary and good pending recovers when healthy',
    () async {
      final p = _Process(_Disk())..ready = false;
      await p.accept(_a);
      final next = p.restart();
      next.native.fail = (op, key, _) => op == 'read';
      await next.recover();
      expect(next.failures, [ShareResolutionStatus.temporary]);
      expect(next.accepted, isEmpty);
      next.native.fail = null;
      await next.ingress.flushPendingUriIfAny(retry: true);
      await _expectAccepted(next, _a, 'eq-a');
    },
  );

  test(
    'pending overwrite failure cannot resurrect old actionable A as new B',
    () async {
      final p = _Process(_Disk())..ready = false;
      await p.accept(_a);
      p.native.fail = (op, key, value) =>
          op == 'write' && key == _stateKey && value!.contains(_b);
      await p.accept(_b);
      expect(p.failures, [ShareResolutionStatus.temporary]);
      final next = p.restart();
      await next.recover();
      expect(next.accepted, isEmpty);
    },
  );

  test(
    'accepted plus overlay write failure leaves one retryable pending intent',
    () async {
      final p = _Process(_Disk());
      p.native.fail = (op, key, value) =>
          op == 'write' &&
          key == _stateKey &&
          (jsonDecode(value!) as Map)['overlay'] != null;
      await p.accept(_a);
      expect(p.accepted, isEmpty);
      final pending = await p.storage.readPendingOpen();
      final next = p.restart();
      await next.recover();
      await _expectAccepted(next, _a, 'eq-a');
      expect(next.accepted.single.clientEventId, pending?.clientEventId);
    },
  );

  test(
    'overlay acknowledgement failure retains instruction, not lost attribution',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      final snap = await p.storage.readOverlaySnapshot();
      p.native.fail = (op, key, _) => op == 'write' && key == _stateKey;
      await expectLater(
        p.storage.clearOverlayIfUnchanged(snap.token),
        throwsStateError,
      );
      final next = p.restart();
      await next.recover();
      await _expectAccepted(next, _a, 'eq-a');
    },
  );

  for (final broken in ['state', 'epoch']) {
    test(
      'logout with $broken write/delete failure still durably revokes old attribution',
      () async {
        final p = _Process(_Disk());
        await p.accept(_a);
        p.native.fail = (op, key, _) =>
            (op == 'write' || op == 'delete') &&
            key == (broken == 'state' ? _stateKey : _epochKey);
        await expectLater(p.storage.clearForLogout(), completes);
        final next = p.restart();
        await next.recover();
        expect(next.accepted, isEmpty);
        expect(
          await next.storage.readAcceptedOpen(equipmentId: 'eq-a'),
          isNull,
        );
      },
    );
  }

  test(
    'legacy cleanup failure cannot cause duplicate legacy recovery',
    () async {
      final p = _Process(_Disk());
      p.disk.values[shareStorageKey('equipment_share_pending_uri')] =
          'https://prokat-bfbec.web.app/e/eq-old?s=$_a';
      p.native.fail = (op, key, _) => op == 'delete';
      await p.recover();
      expect(p.accepted.single.link.equipmentId, 'eq-old');
      final next = p.restart();
      await next.recover();
      expect(next.calls, isEmpty);
      expect(
        next.accepted.single.clientEventId,
        p.accepted.single.clientEventId,
      );
    },
  );

  for (final resolved in [false, true]) {
    test(
      'deferredInstall restart ${resolved ? 'after' : 'before'} resolve uses same recovery with source intact',
      () async {
        final p = _Process(_Disk())..ready = resolved;
        await p.accept(_a, via: ShareOpenVia.deferredInstall);
        final next = p.restart();
        await next.recover();
        await _expectAccepted(next, _a, 'eq-a');
        expect(next.accepted.single.via, ShareOpenVia.deferredInstall);
        expect(next.accepted.single.via.api, isNull);
        expect(next.calls, resolved ? isEmpty : [_a]);
      },
    );
  }

  test('crash after server OPENED acceptance retries stable clientEventId with backend dedup', () async {
    final p = _Process(_Disk());
    await p.accept(_a);
    final open = await p.storage.readOpenReceipt();
    final id = open!.clientEventId!;
    final claim = await p.storage.claimOpenReceipt(id);
    expect(claim?.analytics, isTrue);
    final serverIds = <String>{id};
    // The old process dies after the server commits but before local receipt ack.
    final next = p.restart();
    await next.recover();
    expect(next.calls, isEmpty);
    expect(next.accepted.single.clientEventId, id);
    final retry = await next.storage.claimOpenReceipt(id);
    expect(retry?.analytics, isFalse);
    expect(serverIds.add(id), isFalse);
    await next.storage.finishOpenReceipt(id, retry!.account, delivered: true);
    expect(await next.storage.readOpenReceipt(), isNull);
    expect(
      (await next.storage.readAcceptedOpen(equipmentId: 'eq-a'))?.link.shareId,
      _a,
    );
    final again = next.restart();
    await again.recover();
    expect(again.accepted, isEmpty);
  });

  test(
    'OPENED failure stays retryable without repeating analytics claim',
    () async {
      final p = _Process(_Disk());
      await p.accept(_a);
      final id = p.accepted.single.clientEventId!;
      final claim = await p.storage.claimOpenReceipt(id);
      await p.storage.finishOpenReceipt(id, claim!.account, delivered: false);
      final retry = await p.storage.claimOpenReceipt(id);
      expect(retry?.analytics, isFalse);
      expect(await p.storage.readOpenReceipt(), isNotNull);
      await p.storage.clearForLogout();
      expect(p.storage.receiptIsCurrent(id, retry!.account), isFalse);
      await p.storage.finishOpenReceipt(id, retry.account, delivered: true);
      expect(await p.storage.readOpenReceipt(), isNull);
    },
  );
}
