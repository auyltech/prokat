import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/catalog/catalog_cache.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/catalog_service.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/categories/state/category_provider.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

class _MemoryCatalogCache extends CatalogCache {
  CatalogCacheEntry? disk;
  CatalogBundle? asset;
  int writes = 0;

  @override
  Future<CatalogCacheEntry?> readDisk() async => disk;

  @override
  Future<CatalogBundle> readAsset() async {
    final value = asset;
    if (value == null) {
      throw const FormatException('No catalog asset');
    }
    return value;
  }

  @override
  Future<void> write(CatalogBundle bundle, {DateTime? fetchedAt}) async {
    writes++;
    disk = CatalogCacheEntry(
      bundle: bundle,
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }
}

CatalogCategory _category({
  required String id,
  required String slug,
  required int sortIndex,
  bool isUserVisible = true,
  bool isOwnerVisible = true,
}) {
  return CatalogCategory(
    id: id,
    slug: slug,
    names: LocalizedNames(en: slug),
    sortIndex: sortIndex,
    isUserVisible: isUserVisible,
    isOwnerVisible: isOwnerVisible,
  );
}

CatalogBundle _bundle({
  required String version,
  List<CatalogCategory>? categories,
}) {
  return CatalogBundle(
    version: version,
    cities: const [],
    categories:
        categories ??
        [
          const CatalogCategory(
            id: 'category-1',
            slug: 'excavators',
            names: LocalizedNames(en: 'Excavators'),
            sortIndex: 1,
            isUserVisible: true,
            isOwnerVisible: true,
          ),
        ],
    units: const [],
    specs: const [],
    specOptions: const [],
    categorySpecs: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'catalogue stays fresh for 24 hours and hard refresh still fetches',
    () async {
      var calls = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls++;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'data': _bundle(version: 'v$calls').toJson()},
              ),
            );
          },
        ),
      );
      final cache = _MemoryCatalogCache()
        ..disk = CatalogCacheEntry(
          bundle: _bundle(version: 'disk'),
          fetchedAt: DateTime.now(),
        );

      final container = ProviderContainer(
        overrides: [
          catalogCacheProvider.overrideWithValue(cache),
          catalogServiceProvider.overrideWithValue(
            CatalogService(_TestApiClient(dio)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final categories = await container.read(categoriesProvider.future);
      expect(categories.items.single.id, 'category-1');
      expect(calls, 1);

      await container.read(categoriesProvider.notifier).refreshIfStale();
      expect(calls, 1);

      await container.read(categoriesProvider.notifier).refresh();
      expect(calls, 2);
    },
  );

  test('categoriesProvider exposes every user-visible category', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': _bundle(
                  version: 'visible-categories',
                  categories: [
                    _category(
                      id: 'vacuum',
                      slug: 'vacuum_trucks',
                      sortIndex: 2,
                    ),
                    _category(id: 'crane', slug: 'cranes', sortIndex: 1),
                    _category(
                      id: 'hidden',
                      slug: 'hidden',
                      sortIndex: 3,
                      isUserVisible: false,
                    ),
                  ],
                ).toJson(),
              },
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        catalogCacheProvider.overrideWithValue(_MemoryCatalogCache()),
        catalogServiceProvider.overrideWithValue(
          CatalogService(_TestApiClient(dio)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final categories = await container.read(categoriesProvider.future);

    expect(categories.items.map((item) => item.id), ['crane', 'vacuum']);
  });
}
