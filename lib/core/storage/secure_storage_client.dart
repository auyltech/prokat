import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageClient {
  static const _androidOptions = AndroidOptions();

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  // Single initialized instance
  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
}
