import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import 'package:prokat/features/equipment_share/equipment_share_booking_intent.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';

final equipmentShareStorageProvider = Provider<EquipmentShareStorage>((ref) {
  return EquipmentShareStorage();
});

class EquipmentShareStorage {
  final FlutterSecureStorage _storage;

  EquipmentShareStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? SecureStorageClient.instance;

  String get _pendingKey => Env.isLocal
      ? 'local_equipment_share_pending_uri'
      : 'equipment_share_pending_uri';

  String get _intentKey => Env.isLocal
      ? 'local_equipment_share_booking_intent'
      : 'equipment_share_booking_intent';

  String get _overlayKey =>
      Env.isLocal ? 'local_equipment_share_overlay' : 'equipment_share_overlay';

  String get _referrerCheckedKey => Env.isLocal
      ? 'local_equipment_share_install_referrer_checked'
      : 'equipment_share_install_referrer_checked';

  Future<void> savePendingOpen(EquipmentShareOpen open) async {
    await _storage.write(key: _pendingKey, value: jsonEncode(open.toJson()));
  }

  /// Also reads the legacy plain-URI value written by older builds.
  Future<EquipmentShareOpen?> readPendingOpen() async {
    try {
      final raw = await _storage.read(key: _pendingKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final open = EquipmentShareOpen.tryParse(raw);
      if (open == null) {
        await clearPendingUri();
        return null;
      }
      return open;
    } catch (_) {
      await clearPendingUri();
      return null;
    }
  }

  Future<void> clearPendingUri() async {
    try {
      await _storage.delete(key: _pendingKey);
    } catch (_) {}
  }

  Future<void> saveBookingIntent(EquipmentShareBookingIntent intent) async {
    await _storage.write(key: _intentKey, value: jsonEncode(intent.toJson()));
  }

  Future<EquipmentShareBookingIntent?> readBookingIntent() async {
    try {
      final raw = await _storage.read(key: _intentKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final intent = EquipmentShareBookingIntent.tryParse(raw);
      if (intent == null) {
        await clearBookingIntent();
        return null;
      }
      return intent;
    } catch (_) {
      await clearBookingIntent();
      return null;
    }
  }

  Future<void> clearBookingIntent() async {
    try {
      await _storage.delete(key: _intentKey);
    } catch (_) {}
  }

  // Secure storage calls are separate native round-trips, so "read, then
  // delete" is not atomic. Overlay operations run one at a time, and every
  // mutation bumps the generation, so a consumer can delete only the exact
  // overlay it read. Holds only for callers sharing this instance — use
  // [equipmentShareStorageProvider].
  Future<void> _overlayQueue = Future<void>.value();
  int _overlayGeneration = 0;

  Future<T> _overlayOp<T>(Future<T> Function() op) {
    final run = _overlayQueue.then((_) => op());
    _overlayQueue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> saveOverlay(EquipmentShareOverlay overlay) {
    return _overlayOp(() async {
      _overlayGeneration++;
      await _storage.write(
        key: _overlayKey,
        value: jsonEncode(overlay.toJson()),
      );
    });
  }

  /// The stored overlay plus a token for [clearOverlayIfUnchanged].
  Future<({EquipmentShareOverlay? overlay, int token})> readOverlaySnapshot() {
    return _overlayOp(() async {
      final overlay = await _readOverlay();
      return (overlay: overlay, token: _overlayGeneration);
    });
  }

  /// Deletes the overlay only if nothing wrote or cleared it since [token]
  /// was read. Returns false and keeps the newer overlay otherwise.
  Future<bool> clearOverlayIfUnchanged(int token) {
    return _overlayOp(() async {
      if (token != _overlayGeneration) return false;
      await _deleteOverlay();
      return true;
    });
  }

  Future<void> clearOverlay() => _overlayOp(_deleteOverlay);

  Future<EquipmentShareOverlay?> _readOverlay() async {
    try {
      final raw = await _storage.read(key: _overlayKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final overlay = EquipmentShareOverlay.tryParse(raw);
      if (overlay == null) {
        await _deleteOverlay();
        return null;
      }
      return overlay;
    } catch (_) {
      await _deleteOverlay();
      return null;
    }
  }

  Future<void> _deleteOverlay() async {
    _overlayGeneration++;
    try {
      await _storage.delete(key: _overlayKey);
    } catch (_) {}
  }

  Future<bool> wasInstallReferrerChecked() async {
    try {
      return await _storage.read(key: _referrerCheckedKey) == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> markInstallReferrerChecked() async {
    try {
      await _storage.write(key: _referrerCheckedKey, value: '1');
    } catch (_) {}
  }
}
