import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/media/media_cache.dart';
import 'package:prokat/core/media/media_file_service.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

final mediaCacheControllerProvider = Provider<MediaCacheController>((ref) {
  final controller = MediaCacheController(
    secureStorage: ref.watch(secureStorageProvider),
    requestMetadata: ref.watch(clientRequestMetadataProvider),
  );

  ref.listen(authProvider, (_, next) {
    unawaited(controller.setNamespace(mediaCacheNamespace(next.session)));
  }, fireImmediately: true);

  return controller;
});

final mediaCacheManagerProvider = Provider<CacheManager>((ref) {
  final controller = ref.watch(mediaCacheControllerProvider);
  ref.watch(authProvider);
  return controller.current;
});
