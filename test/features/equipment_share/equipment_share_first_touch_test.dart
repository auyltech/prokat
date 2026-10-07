import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/features/equipment_share/equipment_share_first_touch.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';

const _shareA = 'AbCdEfGhIjKlMnOpQr_-12';
const _shareB = 'ZyXwVuTsRqPoNmLkJi_-98';
final _now = DateTime.utc(2026, 10, 6, 12);

String get _key => Env.isLocal
    ? 'local_equipment_share_first_touch'
    : 'equipment_share_first_touch';

FirstTouchAttribution _touch({
  String? shareId = _shareA,
  String equipmentId = 'eq-a',
  ShareOpenVia via = ShareOpenVia.appLink,
  bool firstRun = false,
  DateTime? receivedAt,
}) => FirstTouchAttribution(
  shareId: shareId,
  equipmentId: equipmentId,
  via: via,
  firstShareBootstrapRun: firstRun,
  receivedAt: receivedAt ?? _now,
);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('first valid touch wins', () async {
    final store = EquipmentShareFirstTouchStore(now: () => _now);
    await store.saveIfEmpty(_touch());
    await store.saveIfEmpty(_touch(shareId: _shareB, equipmentId: 'eq-b'));

    final saved = await store.readValid();
    expect(saved?.shareId, _shareA);
    expect(saved?.equipmentId, 'eq-a');
  });

  test('expired entry is replaced', () async {
    final store = EquipmentShareFirstTouchStore(now: () => _now);
    await store.saveIfEmpty(
      _touch(receivedAt: _now.subtract(const Duration(days: 31))),
    );
    await store.saveIfEmpty(_touch(shareId: _shareB, equipmentId: 'eq-b'));

    final saved = await store.readValid();
    expect(saved?.shareId, _shareB);
    expect(saved?.equipmentId, 'eq-b');
  });

  test('readValid deletes expired entry', () async {
    final stored = _touch(receivedAt: _now.subtract(const Duration(days: 31)));
    FlutterSecureStorage.setMockInitialValues({
      _key: jsonEncode(stored.toJson()),
    });
    final store = EquipmentShareFirstTouchStore(now: () => _now);

    expect(await store.readValid(), isNull);
    expect(await const FlutterSecureStorage().read(key: _key), isNull);
  });

  test('corrupt JSON is deleted', () async {
    FlutterSecureStorage.setMockInitialValues({_key: '{broken'});
    final store = EquipmentShareFirstTouchStore(now: () => _now);

    expect(await store.readValid(), isNull);
    expect(await const FlutterSecureStorage().read(key: _key), isNull);
  });

  test('api JSON uses backend via values and UTC firstTouchAt', () {
    final localTime = DateTime.parse('2026-10-06T17:00:00+05:00');

    expect(_touch(receivedAt: localTime).toApiJson(), {
      'shareId': _shareA,
      'equipmentId': 'eq-a',
      'openVia': 'APP_LINK',
      'firstShareBootstrapRun': false,
      'firstTouchAt': '2026-10-06T12:00:00.000Z',
    });
    expect(
      _touch(
        via: ShareOpenVia.installReferrer,
        firstRun: true,
      ).toApiJson()['openVia'],
      'INSTALL_REFERRER',
    );
  });

  test('valid before 30 days and exactly at 30 days', () {
    final touch = _touch();

    expect(touch.isExpired(_now.add(const Duration(days: 29))), isFalse);
    expect(touch.isExpired(_now.add(const Duration(days: 30))), isFalse);
  });

  test(
    'install today remains valid on signup-equivalent read after 2 days',
    () async {
      final store = EquipmentShareFirstTouchStore(now: () => _now);
      await store.saveIfEmpty(_touch());

      final saved = await store.readValid(
        now: _now.add(const Duration(days: 2)),
      );
      expect(saved?.shareId, _shareA);
    },
  );

  test('strictly after 30 days expires', () {
    final touch = _touch();

    expect(
      touch.isExpired(_now.add(const Duration(days: 30, microseconds: 1))),
      isTrue,
    );
  });

  test('saved attribution survives a new store instance', () async {
    await EquipmentShareFirstTouchStore(now: () => _now).saveIfEmpty(_touch());

    final restarted = EquipmentShareFirstTouchStore(now: () => _now);
    expect((await restarted.readValid())?.shareId, _shareA);
  });

  test('optional shareId round-trips as null', () {
    final original = _touch(shareId: null);
    final parsed = FirstTouchAttribution.tryParse(
      jsonEncode(original.toJson()),
    );

    expect(parsed?.shareId, isNull);
    expect(parsed?.equipmentId, 'eq-a');
    expect(parsed?.receivedAt, _now);
    expect(parsed?.toApiJson().containsKey('shareId'), isFalse);
  });
}
