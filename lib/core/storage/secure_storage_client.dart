import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageClient {
  // Hardened options for secure at-rest data encryption
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  // Single initialized instance
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
}
