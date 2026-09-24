import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';

CatalogBundle catalog({bool userVisible = true, bool ownerVisible = true}) {
  return CatalogBundle.fromJson({
    'version': 'visibility-test',
    'categories': [
      {
        'id': 'vacuum',
        'slug': 'vacuum_trucks',
        'names': {'ru': 'Вакуумные машины'},
        'isUserVisible': userVisible,
        'isOwnerVisible': ownerVisible,
      },
    ],
  });
}

void main() {
  test('client visibility follows admin flag independently of owner flag', () {
    final bundle = catalog(userVisible: false);
    expect(vacuumTrucksCategories(bundle), isEmpty);
    expect(vacuumTrucksCategory(bundle, forOwner: true)?.id, 'vacuum');
  });

  test('owner visibility follows admin flag independently of client flag', () {
    final bundle = catalog(ownerVisible: false);
    expect(vacuumTrucksCategories(bundle).single.id, 'vacuum');
    expect(vacuumTrucksCategory(bundle, forOwner: true), isNull);
  });

  test('removed category is not restored from a hardcoded fallback', () {
    final bundle = CatalogBundle.fromJson({
      'version': 'empty',
      'categories': [],
    });
    expect(vacuumTrucksCategories(bundle), isEmpty);
    expect(vacuumTrucksCategory(bundle, forOwner: true), isNull);
    expect(vacuumTrucksCategories(null), isEmpty);
  });
}
