import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import 'package:prokat/features/equipment_share/equipment_share_booking_intent.dart';
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

  Future<void> savePendingUri(String uri) async {
    await _storage.write(key: _pendingKey, value: uri);
  }

  Future<String?> readPendingUri() async {
    try {
      final value = await _storage.read(key: _pendingKey);
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
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

  Future<void> saveOverlay(EquipmentShareOverlay overlay) async {
    await _storage.write(key: _overlayKey, value: jsonEncode(overlay.toJson()));
  }

  Future<EquipmentShareOverlay?> readOverlay() async {
    try {
      final raw = await _storage.read(key: _overlayKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final overlay = EquipmentShareOverlay.tryParse(raw);
      if (overlay == null) {
        await clearOverlay();
        return null;
      }
      return overlay;
    } catch (_) {
      await clearOverlay();
      return null;
    }
  }

  Future<void> clearOverlay() async {
    try {
      await _storage.delete(key: _overlayKey);
    } catch (_) {}
  }
}
