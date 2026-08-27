import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/features/catalog/catalog_cache.dart';
import 'package:prokat/features/catalog/catalog_service.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';

final catalogCacheProvider = Provider<CatalogCache>((ref) {
  return CatalogCache();
});

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(ref.watch(apiClientProvider));
});

final catalogProvider =
    AsyncNotifierProvider<CatalogNotifier, CatalogBundle>(CatalogNotifier.new);

class CatalogNotifier extends AsyncNotifier<CatalogBundle> {
  static const staleAfter = Duration(hours: 24);

  CatalogService get _api => ref.read(catalogServiceProvider);
  CatalogCache get _cache => ref.read(catalogCacheProvider);

  DateTime? _fetchedAt;
  Future<void>? _refreshing;

  @override
  Future<CatalogBundle> build() async {
    final disk = await _cache.readDisk();
    CatalogBundle? local = disk?.bundle;
    _fetchedAt = disk?.fetchedAt;

    local ??= await _loadAsset();

    try {
      final next = await _fetchAndStore(ifNoneMatch: local?.version);
      if (next != null) return next;
    } catch (_) {
      if (local != null) return local;
      rethrow;
    }

    if (local != null) return local;
    throw Exception('Catalog unavailable');
  }

  Future<CatalogBundle?> _loadAsset() async {
    try {
      return await _cache.readAsset();
    } catch (_) {
      return null;
    }
  }

  Future<CatalogBundle?> _fetchAndStore({String? ifNoneMatch}) async {
    final result = await _api.fetchBundle(ifNoneMatch: ifNoneMatch);
    if (result.notModified) {
      _fetchedAt = DateTime.now();
      final current = state.valueOrNull;
      if (current != null) {
        await _cache.write(current, fetchedAt: _fetchedAt);
        return current;
      }
      return null;
    }

    final bundle = result.bundle;
    if (bundle == null) return null;
    _fetchedAt = DateTime.now();
    await _cache.write(bundle, fetchedAt: _fetchedAt);
    return bundle;
  }

  Future<void> refresh() {
    final active = _refreshing;
    if (active != null) return active;
    final operation = _refresh();
    _refreshing = operation;
    return operation.whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    final previous = state.valueOrNull;
    try {
      final next = await _fetchAndStore(ifNoneMatch: previous?.version);
      if (next != null) {
        state = AsyncData(next);
        return;
      }
      if (previous != null) state = AsyncData(previous);
    } catch (error, stackTrace) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> refreshIfStale() async {
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    final fetchedAt = _fetchedAt;
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt) >= staleAfter) {
      await refresh();
    }
  }
}

List<String> catalogCityKeys(CatalogBundle? catalog) {
  final slugs = catalog?.visibleCities.map((item) => item.slug).toList() ?? [];
  if (slugs.isNotEmpty) return slugs;
  return cities;
}

String catalogCityLabel({
  required String? city,
  required String languageCode,
  required CatalogBundle? catalog,
  required String Function(String? city) fallback,
}) {
  final match = catalog?.cityBySlugOrName(city);
  if (match != null) return match.label(languageCode);
  return fallback(city);
}
