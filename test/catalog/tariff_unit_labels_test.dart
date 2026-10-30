import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/catalog/tariff_unit_labels.dart';

CatalogTariffUnit _unit({
  required String code,
  String ru = '',
  String en = '',
  String kk = '',
  int sortIndex = 0,
  bool isActive = true,
}) {
  return CatalogTariffUnit(
    id: 'id-$code',
    code: code,
    names: LocalizedNames(ru: ru, en: en, kk: kk),
    sortIndex: sortIndex,
    isActive: isActive,
  );
}

CatalogBundle _bundle(List<CatalogTariffUnit>? tariffUnits) {
  return CatalogBundle(
    version: 'test',
    cities: const [],
    categories: const [],
    units: const [],
    tariffUnits: tariffUnits,
    specs: const [],
    specOptions: const [],
    categorySpecs: const [],
  );
}

final _legacy = <String, Map<String, String>>{
  'ru': {
    'PER_HOUR': 'за час',
    'PER_DAY': 'за день',
    'PER_TRIP': 'за рейс',
    'PER_CUBIC_METER': 'за м³',
  },
  'en': {
    'PER_HOUR': 'per hour',
    'PER_DAY': 'per day',
    'PER_TRIP': 'per trip',
    'PER_CUBIC_METER': 'per m³',
  },
  'kk': {
    'PER_HOUR': 'сағатына',
    'PER_DAY': 'күніне',
    'PER_TRIP': 'рейске',
    'PER_CUBIC_METER': 'м³',
  },
};

String? _legacyLookup(String code, String languageCode) {
  return _legacy[languageCode]?[code];
}

void main() {
  final catalog = _bundle([
    _unit(
      code: 'PER_HOUR',
      ru: 'за час',
      en: 'per hour',
      kk: 'сағатына',
      sortIndex: 0,
    ),
    _unit(
      code: 'PER_DAY',
      ru: 'за день',
      en: 'per day',
      kk: 'күніне',
      sortIndex: 1,
    ),
    _unit(
      code: 'PER_TRIP',
      ru: 'за рейс',
      en: 'per trip',
      kk: 'рейске',
      sortIndex: 2,
    ),
    _unit(
      code: 'PER_CUBIC_METER',
      ru: 'за м³',
      en: 'per m³',
      kk: 'м³',
      sortIndex: 3,
    ),
    _unit(
      code: 'PER_MONTH',
      ru: 'за месяц',
      en: 'per month',
      kk: 'айына',
      sortIndex: 4,
    ),
    _unit(
      code: 'PER_TONNE',
      ru: 'за тонну',
      en: 'per tonne',
      kk: 'тоннаға',
      sortIndex: 5,
    ),
  ]);

  group('normalizeTariffLanguageCode', () {
    test('strips regional suffixes', () {
      expect(normalizeTariffLanguageCode('kk-KZ'), 'kk');
      expect(normalizeTariffLanguageCode('en_US'), 'en');
      expect(normalizeTariffLanguageCode('ru'), 'ru');
      expect(normalizeTariffLanguageCode('xx'), 'ru');
    });
  });

  group('resolveTariffUnitLabel', () {
    test('resolves PER_HOUR on ru/en/kk from catalog', () {
      expect(
        resolveTariffUnitLabel(
          code: 'PER_HOUR',
          languageCode: 'ru',
          catalog: catalog,
        ),
        'за час',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_HOUR',
          languageCode: 'en',
          catalog: catalog,
        ),
        'per hour',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_HOUR',
          languageCode: 'kk',
          catalog: catalog,
        ),
        'сағатына',
      );
    });

    test('resolves PER_DAY and PER_TRIP on all locales', () {
      expect(
        resolveTariffUnitLabel(
          code: 'PER_DAY',
          languageCode: 'ru',
          catalog: catalog,
        ),
        'за день',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_DAY',
          languageCode: 'en',
          catalog: catalog,
        ),
        'per day',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_DAY',
          languageCode: 'kk',
          catalog: catalog,
        ),
        'күніне',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_TRIP',
          languageCode: 'ru',
          catalog: catalog,
        ),
        'за рейс',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_TRIP',
          languageCode: 'en',
          catalog: catalog,
        ),
        'per trip',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_TRIP',
          languageCode: 'kk',
          catalog: catalog,
        ),
        'рейске',
      );
    });

    test('resolves new codes absent from ARB', () {
      expect(
        resolveTariffUnitLabel(
          code: 'PER_MONTH',
          languageCode: 'ru',
          catalog: catalog,
        ),
        'за месяц',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_TONNE',
          languageCode: 'kk',
          catalog: catalog,
        ),
        'тоннаға',
      );
    });

    test('uses regional locale suffix', () {
      expect(
        resolveTariffUnitLabel(
          code: 'PER_HOUR',
          languageCode: 'kk-KZ',
          catalog: catalog,
        ),
        'сағатына',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_HOUR',
          languageCode: 'en-US',
          catalog: catalog,
        ),
        'per hour',
      );
    });

    test('empty current locale falls back to Russian on same unit', () {
      final sparse = _bundle([
        _unit(code: 'PER_HOUR', ru: 'за час', en: '', kk: ''),
      ]);
      expect(
        resolveTariffUnitLabel(
          code: 'PER_HOUR',
          languageCode: 'kk',
          catalog: sparse,
        ),
        'за час',
      );
    });

    test('missing all translations returns the same code', () {
      final emptyNames = _bundle([
        _unit(code: 'PER_MONTH', ru: '  ', en: '', kk: ''),
      ]);
      expect(
        resolveTariffUnitLabel(
          code: 'PER_MONTH',
          languageCode: 'en',
          catalog: emptyNames,
          legacyLookup: _legacyLookup,
        ),
        'PER_MONTH',
      );
    });

    test('absent catalog unit uses legacy ARB for historic codes', () {
      expect(
        resolveTariffUnitLabel(
          code: 'PER_HOUR',
          languageCode: 'ru',
          catalog: _bundle(null),
          legacyLookup: _legacyLookup,
        ),
        'за час',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_TRIP',
          languageCode: 'en',
          catalog: null,
          legacyLookup: _legacyLookup,
        ),
        'per trip',
      );
    });

    test('unknown code without catalog returns itself, not PER_TRIP', () {
      expect(
        resolveTariffUnitLabel(
          code: 'PER_WEEK',
          languageCode: 'ru',
          catalog: null,
          legacyLookup: _legacyLookup,
        ),
        'PER_WEEK',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_WEEK',
          languageCode: 'ru',
          catalog: _bundle(const []),
        ),
        'PER_WEEK',
      );
      expect(
        resolveTariffUnitLabel(
          code: 'PER_WEEK',
          languageCode: 'ru',
          catalog: null,
          legacyLookup: _legacyLookup,
        ),
        isNot('PER_TRIP'),
      );
    });

    test('locale switch on loaded catalog needs no network', () {
      // Same in-memory catalog object; only languageCode changes.
      final ru = resolveTariffUnitLabel(
        code: 'PER_HOUR',
        languageCode: 'ru',
        catalog: catalog,
      );
      final en = resolveTariffUnitLabel(
        code: 'PER_HOUR',
        languageCode: 'en',
        catalog: catalog,
      );
      final kk = resolveTariffUnitLabel(
        code: 'PER_HOUR',
        languageCode: 'kk',
        catalog: catalog,
      );
      expect(ru, 'за час');
      expect(en, 'per hour');
      expect(kk, 'сағатына');
      expect(identical(catalog, catalog), isTrue);
    });
  });

  group('formatPriceWithTariffUnit', () {
    test('formats amount without slash before unit', () {
      final line = formatPriceWithTariffUnit(price: 15000, unitLabel: 'за час');
      expect(line, '15 000 ₸ за час');
      expect(line.contains('/'), isFalse);
      expect(line.contains('/час'), isFalse);

      expect(
        formatPriceWithTariffUnitCode(
          price: 15000,
          code: 'PER_HOUR',
          languageCode: 'en',
          catalog: catalog,
        ),
        '15 000 ₸ per hour',
      );
      expect(
        formatPriceWithTariffUnitCode(
          price: 15000,
          code: 'PER_HOUR',
          languageCode: 'kk',
          catalog: catalog,
        ),
        '15 000 ₸ сағатына',
      );
    });
  });

  group('buildTariffUnitSelectOptions', () {
    test('uses active units, sort order and raw codes as values', () {
      final withInactive = _bundle([
        _unit(
          code: 'PER_HOUR',
          ru: 'за час',
          en: 'per hour',
          kk: 'сағатына',
          sortIndex: 0,
        ),
        _unit(
          code: 'PER_MONTH',
          ru: 'за месяц',
          en: 'per month',
          kk: 'айына',
          sortIndex: 1,
          isActive: false,
        ),
        _unit(
          code: 'PER_TONNE',
          ru: 'за тонну',
          en: 'per tonne',
          kk: 'тоннаға',
          sortIndex: 2,
        ),
      ]);

      final options = buildTariffUnitSelectOptions(
        catalog: withInactive,
        languageCode: 'ru',
      );

      expect(options.map((o) => o.value).toList(), ['PER_HOUR', 'PER_TONNE']);
      expect(options.map((o) => o.label).toList(), ['за час', 'за тонну']);
    });

    test('includeCode keeps historical inactive value without remapping', () {
      final options = buildTariffUnitSelectOptions(
        catalog: _bundle([
          _unit(
            code: 'PER_HOUR',
            ru: 'за час',
            en: 'per hour',
            kk: 'сағатына',
            sortIndex: 0,
          ),
          _unit(
            code: 'PER_MONTH',
            ru: 'за месяц',
            en: 'per month',
            kk: 'айына',
            sortIndex: 1,
            isActive: false,
          ),
        ]),
        languageCode: 'en',
        includeCode: 'PER_MONTH',
      );

      expect(options.map((o) => o.value).toList(), ['PER_HOUR', 'PER_MONTH']);
      expect(options.last.label, 'per month');
    });

    test('null tariffUnits falls back to historic four codes', () {
      final options = buildTariffUnitSelectOptions(
        catalog: _bundle(null),
        languageCode: 'ru',
        legacyLookup: _legacyLookup,
      );
      expect(options.map((o) => o.value).toSet(), legacyTariffUnitCodes);
      expect(options.firstWhere((o) => o.value == 'PER_HOUR').label, 'за час');
    });
  });
}
