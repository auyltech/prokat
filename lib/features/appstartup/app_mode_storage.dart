import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';

enum AppMode { clientMode, ownerMode }

class AppModeStorage {
  static const _modeKey = 'app_mode';

  final FlutterSecureStorage _storage;

  AppModeStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? SecureStorageClient.instance;

  Future<void> saveMode(AppMode mode) async {
    await _storage.write(key: _modeKey, value: mode.name);
  }

  Future<AppMode?> readMode() async {
    final value = await _storage.read(key: _modeKey);
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final mode in AppMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }

    return null;
  }

  Future<void> clearMode() async {
    await _storage.delete(key: _modeKey);
  }
}
