import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:prokat/core/media/resolve_media_url.dart';

/// Collects absolute API `/media/...` URLs suitable for disk-cache warming.
List<String> mediaPrefetchUrls(Iterable<String?> rawUrls) {
  final urls = <String>{};
  for (final raw in rawUrls) {
    final resolved = resolveMediaUrl(raw);
    if (resolved == null || resolved.isEmpty) continue;
    if (resolved.startsWith('assets/')) continue;
    if (!isApiMediaUrl(resolved)) continue;
    urls.add(resolved);
  }
  return urls.toList(growable: false);
}

/// Warms [CacheManager] disk entries in the background (no Flutter mem cache).
class MediaImagePrefetcher {
  MediaImagePrefetcher({required this.cacheManager, this.concurrency = 3});

  final CacheManager cacheManager;
  final int concurrency;

  /// Downloads missing files. Errors are swallowed; safe to fire-and-forget.
  ///
  /// When [isCurrent] returns false, remaining work stops (newer prefetch won).
  Future<void> warm(
    Iterable<String?> rawUrls, {
    bool Function()? isCurrent,
  }) async {
    final urls = mediaPrefetchUrls(rawUrls);
    if (urls.isEmpty) return;

    final remaining = List<String>.from(urls);
    final workers = List.generate(
      concurrency.clamp(1, remaining.length),
      (_) => _worker(remaining, isCurrent),
    );
    await Future.wait(workers);
  }

  Future<void> _worker(
    List<String> remaining,
    bool Function()? isCurrent,
  ) async {
    while (true) {
      if (isCurrent != null && !isCurrent()) return;
      if (remaining.isEmpty) return;
      final url = remaining.removeLast();
      try {
        final cached = await cacheManager.getFileFromCache(url);
        if (cached != null && await cached.file.exists()) {
          continue;
        }
        await cacheManager.downloadFile(url);
      } catch (_) {
        // Prefetch must never affect catalog / UI flows.
      }
    }
  }
}
