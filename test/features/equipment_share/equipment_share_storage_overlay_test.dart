import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';

String get _overlayKey =>
    Env.isLocal ? 'local_equipment_share_overlay' : 'equipment_share_overlay';

const _a = EquipmentShareOverlay(path: '/e/eq-a', afterAuth: false);
const _b = EquipmentShareOverlay(path: '/e/eq-b', afterAuth: true);

void main() {
  late EquipmentShareStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = EquipmentShareStorage();
  });

  Future<String?> stored() async =>
      (await storage.readOverlaySnapshot()).overlay?.path;

  test('unchanged overlay is cleared by its reader', () async {
    await storage.saveOverlay(_a);
    final snapshot = await storage.readOverlaySnapshot();

    expect(snapshot.overlay?.path, '/e/eq-a');
    expect(await storage.clearOverlayIfUnchanged(snapshot.token), isTrue);
    expect(await stored(), isNull);
  });

  test('write after an empty read survives the stale clear', () async {
    final snapshot = await storage.readOverlaySnapshot();
    expect(snapshot.overlay, isNull);

    await storage.saveOverlay(_b);

    expect(await storage.clearOverlayIfUnchanged(snapshot.token), isFalse);
    expect(await stored(), '/e/eq-b');
  });

  test('write issued between read and clear survives', () async {
    await storage.saveOverlay(_a);
    final read = storage.readOverlaySnapshot();
    final write = storage.saveOverlay(_b);
    final snapshot = await read;
    final claimed = storage.clearOverlayIfUnchanged(snapshot.token);
    await write;

    expect(snapshot.overlay?.path, '/e/eq-a');
    expect(await claimed, isFalse);
    expect(await stored(), '/e/eq-b');
  });

  test('queued newer write immediately invalidates an older clear', () async {
    await storage.saveOverlay(_a);
    final snapshot = await storage.readOverlaySnapshot();
    final claimed = storage.clearOverlayIfUnchanged(snapshot.token);
    final write = storage.saveOverlay(_b);
    await write;

    expect(await claimed, isFalse);
    expect(await stored(), '/e/eq-b');
  });

  test('the same snapshot cannot be claimed twice', () async {
    await storage.saveOverlay(_a);
    final snapshot = await storage.readOverlaySnapshot();

    final first = storage.clearOverlayIfUnchanged(snapshot.token);
    final second = storage.clearOverlayIfUnchanged(snapshot.token);

    expect(await first, isTrue);
    expect(await second, isFalse);
  });

  test('logout clear invalidates an older snapshot', () async {
    await storage.saveOverlay(_a);
    final snapshot = await storage.readOverlaySnapshot();

    await storage.clearOverlay();

    expect(await storage.clearOverlayIfUnchanged(snapshot.token), isFalse);
    expect(await stored(), isNull);
  });

  test('corrupt overlay reads as empty and is removed', () async {
    FlutterSecureStorage.setMockInitialValues({_overlayKey: '{broken'});
    storage = EquipmentShareStorage();

    final snapshot = await storage.readOverlaySnapshot();

    expect(snapshot.overlay, isNull);
    expect(await const FlutterSecureStorage().read(key: _overlayKey), isNull);
  });

  test('legacy plain-uri overlay still parses', () async {
    FlutterSecureStorage.setMockInitialValues({
      _overlayKey: 'https://prokat-bfbec.web.app/e/eq-1',
    });
    storage = EquipmentShareStorage();

    final snapshot = await storage.readOverlaySnapshot();

    expect(snapshot.overlay?.path, '/e/eq-1');
    expect(snapshot.overlay?.afterAuth, isFalse);
  });
}
