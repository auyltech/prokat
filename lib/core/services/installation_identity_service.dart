import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prokat/core/storage/secure_storage_client.dart';
import 'package:uuid/uuid.dart';

abstract interface class InstallationIdStore {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureInstallationIdStore implements InstallationIdStore {
  static const _key = 'installation_id';

  final FlutterSecureStorage _storage;

  SecureInstallationIdStore({FlutterSecureStorage? storage})
    : _storage = storage ?? SecureStorageClient.instance;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class InstallationIdentityService {
  final InstallationIdStore _store;
  final Uuid _uuid;
  final bool Function() _isSupportedPlatform;

  String? _cachedId;
  Future<String?>? _pendingId;

  InstallationIdentityService({
    InstallationIdStore? store,
    Uuid? uuid,
    bool Function()? isSupportedPlatform,
  }) : _store = store ?? SecureInstallationIdStore(),
       _uuid = uuid ?? const Uuid(),
       _isSupportedPlatform =
           isSupportedPlatform ??
           (() {
             if (kIsWeb) return false;
             return defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS;
           });

  Future<String?> getOrCreate() {
    if (!_isSupportedPlatform()) return Future.value(null);
    if (_cachedId != null) return Future.value(_cachedId);

    return _pendingId ??= _loadOrCreate();
  }

  Future<String?> _loadOrCreate() async {
    final stored = (await _store.read())?.trim();

    if (stored != null && _isUuidV4(stored)) {
      _cachedId = stored;
      return stored;
    }

    final created = _uuid.v4();
    await _store.write(created);
    _cachedId = created;
    return created;
  }

  bool _isUuidV4(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }
}
