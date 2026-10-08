import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import 'package:prokat/features/equipment_share/equipment_share_id.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';

final _equipmentIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

class FirstTouchAttribution {
  const FirstTouchAttribution({
    required this.shareId,
    required this.equipmentId,
    required this.via,
    required this.firstShareBootstrapRun,
    required this.receivedAt,
  });

  final String? shareId;
  final String equipmentId;
  final ShareOpenVia via;
  final bool firstShareBootstrapRun;
  final DateTime receivedAt;

  Map<String, Object?> toJson() => {
    'v': 1,
    'shareId': shareId,
    'equipmentId': equipmentId,
    'via': via.wire,
    'firstShareBootstrapRun': firstShareBootstrapRun,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
  };

  static FirstTouchAttribution? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['v'] != 1) return null;

      final shareId = decoded['shareId'];
      final equipmentId = decoded['equipmentId'];
      final firstRun = decoded['firstShareBootstrapRun'];
      final receivedAt = decoded['receivedAt'];
      if (shareId != null && (shareId is! String || !isValidShareId(shareId))) {
        return null;
      }
      if (equipmentId is! String ||
          !_equipmentIdPattern.hasMatch(equipmentId)) {
        return null;
      }
      if (firstRun is! bool || receivedAt is! String) return null;
      final parsedAt = DateTime.tryParse(receivedAt);
      final via = _viaFromWire(decoded['via']);
      if (parsedAt == null || via == null) return null;

      return FirstTouchAttribution(
        shareId: shareId as String?,
        equipmentId: equipmentId,
        via: via,
        firstShareBootstrapRun: firstRun,
        receivedAt: parsedAt.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  bool isExpired(DateTime now) =>
      now.isAfter(receivedAt.add(const Duration(days: 30)));

  Map<String, Object?> toApiJson() => {
    if (shareId != null) 'shareId': shareId,
    'equipmentId': equipmentId,
    'openVia': via.api,
    'firstShareBootstrapRun': firstShareBootstrapRun,
    'firstTouchAt': receivedAt.toUtc().toIso8601String(),
  };
}

ShareOpenVia? _viaFromWire(Object? value) {
  for (final via in ShareOpenVia.values) {
    if (via.wire == value) return via;
  }
  return null;
}

class EquipmentShareFirstTouchStore {
  EquipmentShareFirstTouchStore({
    FlutterSecureStorage? storage,
    DateTime Function()? now,
  }) : _storage = storage ?? SecureStorageClient.instance,
       _now = now ?? DateTime.now;

  final FlutterSecureStorage _storage;
  final DateTime Function() _now;
  Future<void> _queue = Future<void>.value();

  String get _key => Env.isLocal
      ? 'local_equipment_share_first_touch'
      : 'equipment_share_first_touch';

  Future<T> _op<T>(Future<T> Function() operation) {
    final run = _queue.then((_) => operation());
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> saveIfEmpty(FirstTouchAttribution attribution) {
    return _op(() async {
      final raw = await _storage.read(key: _key);
      final existing = raw == null ? null : FirstTouchAttribution.tryParse(raw);
      if (existing != null && !existing.isExpired(_now())) return;
      await _storage.write(key: _key, value: jsonEncode(attribution.toJson()));
    });
  }

  Future<FirstTouchAttribution?> readValid({DateTime? now}) {
    return _op(() async {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.trim().isEmpty) return null;
      final attribution = FirstTouchAttribution.tryParse(raw);
      if (attribution == null || attribution.isExpired(now ?? _now())) {
        await _storage.delete(key: _key);
        return null;
      }
      return attribution;
    });
  }

  Future<void> clear() => _op(() => _storage.delete(key: _key));
}

final equipmentShareFirstTouchStoreProvider =
    Provider<EquipmentShareFirstTouchStore>(
      (ref) => EquipmentShareFirstTouchStore(),
    );
