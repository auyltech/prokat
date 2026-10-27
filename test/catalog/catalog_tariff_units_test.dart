import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/catalog/catalog_cache.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/catalog_service.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';

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
    // Simulate real disk: encode/decode so presence of keys is preserved.
    final encoded = jsonEncode({
      'fetchedAt': (fetchedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'bundle': bundle.toJson(),
    });
    final decoded = jsonDecode(encoded);
    final map = Map<String, dynamic>.from(decoded as Map);
    final bundleJson = Map<String, dynamic>.from(map['bundle'] as Map);
    disk = CatalogCacheEntry(
      bundle: CatalogBundle.fromJson(bundleJson),
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }
}

CatalogBundle _minimalBundle({
  required String version,
  List<CatalogTariffUnit>? tariffUnits,
  bool omitTariffUnits = false,
}) {
  return CatalogBundle(
    version: version,
    cities: const [],
    categories: const [],
    units: const [],
    tariffUnits: omitTariffUnits ? null : tariffUnits,
    specs: const [],
    specOptions: const [],
    categorySpecs: const [],
  );
}

Map<String, dynamic> _tariffUnitJson({
  String id = 'tu-1',
  String code = 'PER_HOUR',
  String ru = 'за час',
  String en = 'per hour',
  String kk = 'сағатына',
  int sortIndex = 0,
  bool isActive = true,
}) {
  return {
    'id': id,
    'code': code,
    'names': {'ru': ru, 'en': en, 'kk': kk},
    'sortIndex': sortIndex,
    'isActive': isActive,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogTariffUnit', () {
    test('decodes three locale names and keeps unknown codes', () {
      final unit = CatalogTariffUnit.fromJson(
        _tariffUnitJson(
          code: 'PER_TONNE',
          ru: 'за тонну',
          en: 'per tonne',
          kk: 'тоннаға',
        ),
      );

      expect(unit.code, 'PER_TONNE');
      expect(unit.names.ru, 'за тонну');
      expect(unit.names.en, 'per tonne');
      expect(unit.names.kk, 'тоннаға');
      expect(unit.label('ru'), 'за тонну');
      expect(unit.label('en'), 'per tonne');
      expect(unit.label('kk'), 'тоннаға');
    });

    test('round-trips all translations through JSON', () {
      final original = CatalogTariffUnit.fromJson(_tariffUnitJson());
      final restored = CatalogTariffUnit.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
      expect(restored.names.ru, 'за час');
      expect(restored.names.en, 'per hour');
      expect(restored.names.kk, 'сағатына');
    });

    test('missing translation falls back without remapping the code', () {
      final unit = CatalogTariffUnit.fromJson({
        'id': 'tu-x',
        'code': 'PER_MONTH',
        'names': {'ru': '', 'en': 'per month', 'kk': ''},
        'sortIndex': 4,
        'isActive': true,
      });

      expect(unit.label('kk'), 'per month');
      expect(unit.code, 'PER_MONTH');
    });
  });

  group('CatalogBundle.tariffUnits', () {
    test('decodes filled tariffUnits sorted by sortIndex then code', () {
      final bundle = CatalogBundle.fromJson({
        'version': 'v1',
        'cities': [],
        'categories': [],
        'units': [],
        'tariffUnits': [
          _tariffUnitJson(id: 'b', code: 'PER_DAY', sortIndex: 1),
          _tariffUnitJson(id: 'a', code: 'PER_HOUR', sortIndex: 0),
          _tariffUnitJson(
            id: 'c',
            code: 'PER_MONTH',
            ru: 'за месяц',
            en: 'per month',
            kk: 'айына',
            sortIndex: 1,
          ),
        ],
        'specs': [],
        'specOptions': [],
        'categorySpecs': [],
      });

      expect(bundle.hasTariffUnitsField, isTrue);
      expect(bundle.tariffUnits!.map((u) => u.code).toList(), [
        'PER_HOUR',
        'PER_DAY',
        'PER_MONTH',
      ]);
      expect(bundle.tariffUnitByCode('PER_MONTH')!.names.ru, 'за месяц');
    });

    test('absent tariffUnits key stays null (legacy backend)', () {
      final bundle = CatalogBundle.fromJson({
        'version': 'legacy',
        'cities': [],
        'categories': [],
        'units': [],
        'specs': [],
        'specOptions': [],
        'categorySpecs': [],
      });

      expect(bundle.tariffUnits, isNull);
      expect(bundle.hasTariffUnitsField, isFalse);
      expect(bundle.toJson().containsKey('tariffUnits'), isFalse);
      expect(bundle.activeTariffUnits, isEmpty);
      expect(bundle.tariffUnitByCode('PER_HOUR'), isNull);
    });

    test('empty tariffUnits array is preserved through JSON', () {
      final bundle = CatalogBundle.fromJson({
        'version': 'empty',
        'cities': [],
        'categories': [],
        'units': [],
        'tariffUnits': [],
        'specs': [],
        'specOptions': [],
        'categorySpecs': [],
      });

      expect(bundle.tariffUnits, isEmpty);
      expect(bundle.hasTariffUnitsField, isTrue);
      expect(bundle.toJson()['tariffUnits'], isEmpty);

      final restored = CatalogBundle.fromJson(bundle.toJson());
      expect(restored.tariffUnits, isEmpty);
      expect(restored.hasTariffUnitsField, isTrue);
    });

    test('disk-style encode/decode keeps all three translations', () {
      final original = _minimalBundle(
        version: 'cached',
        tariffUnits: [
          CatalogTariffUnit.fromJson(_tariffUnitJson()),
          CatalogTariffUnit.fromJson(
            _tariffUnitJson(
              id: 'tu-2',
              code: 'PER_CUBIC_METER',
              ru: 'за м³',
              en: 'per m³',
              kk: 'м³',
              sortIndex: 3,
            ),
          ),
        ],
      );

      final wire = jsonEncode({
        'fetchedAt': DateTime.now().toUtc().toIso8601String(),
        'bundle': original.toJson(),
      });
      final map = Map<String, dynamic>.from(jsonDecode(wire) as Map);
      final restored = CatalogBundle.fromJson(
        Map<String, dynamic>.from(map['bundle'] as Map),
      );

      expect(restored.tariffUnits, hasLength(2));
      final hour = restored.tariffUnitByCode('PER_HOUR')!;
      expect(hour.names.ru, 'за час');
      expect(hour.names.en, 'per hour');
      expect(hour.names.kk, 'сағатына');
    });

    test('old disk payload without tariffUnits still loads', () {
      final wire = jsonEncode({
        'fetchedAt': '2024-01-01T00:00:00.000Z',
        'bundle': {
          'version': 'old-disk',
          'cities': [],
          'categories': [],
          'units': [],
          'specs': [],
          'specOptions': [],
          'categorySpecs': [],
        },
      });
      final map = Map<String, dynamic>.from(jsonDecode(wire) as Map);
      final restored = CatalogBundle.fromJson(
        Map<String, dynamic>.from(map['bundle'] as Map),
      );

      expect(restored.version, 'old-disk');
      expect(restored.tariffUnits, isNull);
    });
  });

  group('CatalogNotifier + tariffUnits cache', () {
    test('refresh stores tariffUnits and keeps them on 304', () async {
      var calls = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls++;
            final ifNoneMatch = options.headers['If-None-Match']?.toString();
            if (calls > 1 && ifNoneMatch != null && ifNoneMatch.isNotEmpty) {
              handler.resolve(
                Response<dynamic>(requestOptions: options, statusCode: 304),
              );
              return;
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': _minimalBundle(
                    version: 'etag-v1',
                    tariffUnits: [
                      CatalogTariffUnit.fromJson(_tariffUnitJson()),
                    ],
                  ).toJson(),
                },
              ),
            );
          },
        ),
      );

      final cache = _MemoryCatalogCache()
        ..disk = CatalogCacheEntry(
          bundle: _minimalBundle(version: 'disk-old', omitTariffUnits: true),
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

      final first = await container.read(catalogProvider.future);
      expect(first.tariffUnitByCode('PER_HOUR')!.names.ru, 'за час');
      expect(
        cache.disk!.bundle.tariffUnitByCode('PER_HOUR')!.names.kk,
        'сағатына',
      );
      expect(calls, 1);

      await container.read(catalogProvider.notifier).refresh();
      final after304 = container.read(catalogProvider).valueOrNull!;
      expect(after304.tariffUnitByCode('PER_HOUR')!.names.en, 'per hour');
      expect(calls, 2);
      expect(cache.writes, greaterThanOrEqualTo(2));
    });

    test('failed refresh keeps previous tariffUnits on disk', () async {
      var calls = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls++;
            if (calls == 1) {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': _minimalBundle(
                      version: 'good',
                      tariffUnits: [
                        CatalogTariffUnit.fromJson(_tariffUnitJson()),
                      ],
                    ).toJson(),
                  },
                ),
              );
              return;
            }
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'offline',
              ),
            );
          },
        ),
      );

      final cache = _MemoryCatalogCache();
      final container = ProviderContainer(
        overrides: [
          catalogCacheProvider.overrideWithValue(cache),
          catalogServiceProvider.overrideWithValue(
            CatalogService(_TestApiClient(dio)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(catalogProvider.future);
      final writesAfterSuccess = cache.writes;

      await container.read(catalogProvider.notifier).refresh();
      final kept = container.read(catalogProvider).valueOrNull!;
      expect(kept.version, 'good');
      expect(kept.tariffUnitByCode('PER_HOUR')!.names.ru, 'за час');
      expect(
        cache.disk!.bundle.tariffUnitByCode('PER_HOUR')!.names.ru,
        'за час',
      );
      expect(cache.writes, writesAfterSuccess);
      expect(calls, 2);
    });

    test(
      'locale label switching does not trigger catalog network calls',
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
                  data: {
                    'data': _minimalBundle(
                      version: 'locale-v1',
                      tariffUnits: [
                        CatalogTariffUnit.fromJson(_tariffUnitJson()),
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

        final bundle = await container.read(catalogProvider.future);
        expect(calls, 1);

        final unit = bundle.tariffUnitByCode('PER_HOUR')!;
        expect(unit.label('ru'), 'за час');
        expect(unit.label('en'), 'per hour');
        expect(unit.label('kk'), 'сағатына');
        expect(calls, 1);
      },
    );
  });
}
