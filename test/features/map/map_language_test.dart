import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/map/services/map_language.dart';

void main() {
  test('streetsLabelNameProperty maps app languages onto Streets v8 fields', () {
    expect(streetsLabelNameProperty('ru'), 'name_ru');
    expect(streetsLabelNameProperty('en'), 'name_en');
    expect(streetsLabelNameProperty('kk'), 'name');
  });

  test('rewrites road-label coalesce from name_en to name_ru', () {
    const original = [
      'coalesce',
      ['get', 'name_en'],
      ['get', 'name'],
    ];

    expect(
      rewriteStreetsLabelExpression(original, 'name_ru'),
      [
        'coalesce',
        ['get', 'name_ru'],
        ['get', 'name'],
      ],
    );
  });

  test('rewrites nested format/step expressions without touching name_script', () {
    const original = [
      'format',
      [
        'coalesce',
        ['get', 'name_en'],
        ['get', 'name'],
      ],
      {'text-font': 'DIN Pro Regular'},
      ['get', 'name_script'],
      {},
    ];

    expect(
      rewriteStreetsLabelExpression(original, 'name_ru'),
      [
        'format',
        [
          'coalesce',
          ['get', 'name_ru'],
          ['get', 'name'],
        ],
        {'text-font': 'DIN Pro Regular'},
        ['get', 'name_script'],
        {},
      ],
    );
  });

  test('Kazakh falls back to the local OSM name field', () {
    const original = [
      'coalesce',
      ['get', 'name_en'],
      ['get', 'name'],
    ];

    expect(
      rewriteStreetsLabelExpression(original, streetsLabelNameProperty('kk')),
      [
        'coalesce',
        ['get', 'name'],
        ['get', 'name'],
      ],
    );
  });

  test('ignores house numbers and other non-name labels', () {
    const houseNum = ['get', 'house_num'];
    const ref = ['get', 'ref'];

    expect(streetsLabelExpressionUsesLocalizedName(houseNum), isFalse);
    expect(streetsLabelExpressionUsesLocalizedName(ref), isFalse);
    expect(
      streetsLabelExpressionUsesLocalizedName([
        'coalesce',
        ['get', 'name_en'],
        ['get', 'name'],
      ]),
      isTrue,
    );
  });

  test('rewrites token-style text fields', () {
    expect(
      rewriteStreetsLabelExpression('{name_en}', 'name_ru'),
      '{name_ru}',
    );
  });
}
