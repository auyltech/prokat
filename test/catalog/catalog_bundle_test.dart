import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_spec_type.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';

void main() {
  test('CatalogBundle round-trips through JSON', () {
    const original = CatalogBundle(
      version: 'abc123',
      cities: [
        CatalogCity(
          id: 'city-1',
          slug: 'almaty',
          names: LocalizedNames(en: 'Almaty', ru: 'Алматы', kk: 'Алматы'),
          isVisible: true,
          acceptsEquipment: true,
          sortIndex: 1,
        ),
      ],
      categories: [],
      units: [],
      specs: [
        CatalogSpec(
          id: 'spec-1',
          slug: 'fuel_type',
          names: LocalizedNames(
            en: 'Fuel Type',
            ru: 'Тип топлива',
            kk: 'Отын түрі',
          ),
          type: CatalogSpecType.select,
          isActive: true,
        ),
      ],
      specOptions: [
        CatalogSpecOption(
          id: 'opt-1',
          specId: 'spec-1',
          slug: 'diesel',
          names: LocalizedNames(en: 'Diesel', ru: 'Дизель', kk: 'Дизель'),
          sortIndex: 0,
        ),
      ],
      categorySpecs: [],
    );

    final restored = CatalogBundle.fromJson(original.toJson());

    expect(restored.version, 'abc123');
    expect(restored.cities.single.slug, 'almaty');
    expect(restored.cities.single.label('ru'), 'Алматы');
    expect(restored.specs.single.type, CatalogSpecType.select);
    expect(restored.optionsForSpec('spec-1').single.slug, 'diesel');
  });
}
