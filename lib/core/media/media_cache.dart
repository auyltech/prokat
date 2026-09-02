import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:prokat/core/media/media_file_service.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';

class MediaCacheController {
  MediaCacheController({
    required this.secureStorage,
    required this.requestMetadata,
  });

  final AuthSecureStorage secureStorage;
  final ClientRequestMetadataService requestMetadata;

  final Map<String, CacheManager> _managers = {};
  String _namespace = 'guest';

  String get namespace => _namespace;

  CacheManager managerFor(String namespace) {
    return _managers.putIfAbsent(namespace, () {
      return CacheManager(
        Config(
          'prokat-media-$namespace',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
          fileService: MediaHttpFileService(
            secureStorage: secureStorage,
            requestMetadata: requestMetadata,
            namespace: namespace,
            resolveNamespace: _currentNamespace,
          ),
        ),
      );
    });
  }

  CacheManager get current => managerFor(_namespace);

  Future<String> _currentNamespace() async {
    return mediaCacheNamespace(await secureStorage.readSession());
  }

  Future<void> setNamespace(String namespace) async {
    if (namespace == _namespace) {
      return;
    }

    final previous = _namespace;
    _namespace = namespace;
    managerFor(namespace);

    final oldManager = _managers.remove(previous);
    if (oldManager != null) {
      unawaited(oldManager.emptyCache());
    }
  }
}
