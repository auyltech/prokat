import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';

void main() {
  const catalog = CatalogBundle(
    version: 'test',
    cities: [
      CatalogCity(
        id: 'city-1',
        slug: 'atyrau',
        names: LocalizedNames(en: 'Atyrau', ru: 'Атырау', kk: 'Атырау'),
        isVisible: true,
        acceptsEquipment: true,
        sortIndex: 0,
      ),
      CatalogCity(
        id: 'city-2',
        slug: 'almaty',
        names: LocalizedNames(en: 'Almaty', ru: 'Алматы', kk: 'Алматы'),
        isVisible: true,
        acceptsEquipment: true,
        sortIndex: 1,
      ),
    ],
    categories: [],
    units: [],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );

  test('catalogCityLabel maps slug and latin name to locale names', () {
    expect(
      catalogCityLabel(city: 'atyrau', languageCode: 'ru', catalog: catalog),
      'Атырау',
    );
    expect(
      catalogCityLabel(city: 'Atyrau', languageCode: 'ru', catalog: catalog),
      'Атырау',
    );
    expect(
      catalogCityLabel(city: 'Almaty', languageCode: 'kk', catalog: catalog),
      'Алматы',
    );
    expect(
      catalogCityLabel(city: 'atyrau', languageCode: 'en', catalog: catalog),
      'Atyrau',
    );
  });

  test('catalogCityLabel keeps unknown tokens and empty values', () {
    expect(
      catalogCityLabel(city: 'Aktau', languageCode: 'ru', catalog: catalog),
      'Aktau',
    );
    expect(
      catalogCityLabel(city: 'atyrau', languageCode: 'ru', catalog: null),
      'atyrau',
    );
    expect(
      catalogCityLabel(city: null, languageCode: 'ru', catalog: catalog),
      '',
    );
  });
}
