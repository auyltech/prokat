import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/media/media_providers.dart';
import 'package:prokat/core/media/resolve_media_url.dart';

ImageProvider? mediaImageProvider(WidgetRef ref, String? rawUrl) {
  final resolved = resolveMediaUrl(rawUrl);
  if (resolved == null || resolved.isEmpty) {
    return null;
  }

  if (isApiMediaUrl(resolved)) {
    return CachedNetworkImageProvider(
      resolved,
      cacheManager: ref.read(mediaCacheManagerProvider),
    );
  }

  return NetworkImage(resolved);
}
