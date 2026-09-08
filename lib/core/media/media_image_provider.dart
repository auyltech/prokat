import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/media/media_providers.dart';
import 'package:prokat/core/media/resolve_media_url.dart';

/// No-op for [CircleAvatar.onBackgroundImageError] / image stream failures.
///
/// Without an error listener, Flutter reports missing media (e.g. 404 avatars)
/// via [FlutterError.onError], which Crashlytics records as fatal.
void ignoreMediaImageLoadError(Object error, [StackTrace? stackTrace]) {}

ImageProvider? mediaImageProvider(WidgetRef ref, String? rawUrl) {
  final resolved = resolveMediaUrl(rawUrl);
  if (resolved == null || resolved.isEmpty) {
    return null;
  }

  if (isApiMediaUrl(resolved)) {
    return CachedNetworkImageProvider(
      resolved,
      cacheManager: ref.read(mediaCacheManagerProvider),
      // Marks the load failure as handled so ImageStreamCompleter does not
      // escalate it to FlutterError / Crashlytics.
      errorListener: ignoreMediaImageLoadError,
    );
  }

  return NetworkImage(resolved);
}
