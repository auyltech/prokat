import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';

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
}
