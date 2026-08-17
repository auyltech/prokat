import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/state/equipment_state.dart';
import 'package:prokat/features/locations/models/location_model.dart';

const _category = Category(id: 'cat-1', name: 'Excavator', sortIndex: 1);

final _location = LocationModel(
  service: 'ADDRESS',
  street: 'Abay 1',
  city: 'Almaty',
  country: 'KZ',
  longitude: 76.9,
  latitude: 43.2,
);

void main() {
  group('EquipmentState.copyWith', () {
    test('retains category and filters when they are omitted', () {
      final state = EquipmentState(
        query: 'bobcat',
        searchCity: 'Almaty',
        searchCategoryId: 'cat-1',
        category: _category,
        location: _location,
      );

      final updated = state.copyWith(query: 'crane');

      expect(updated.query, 'crane');
      expect(updated.searchCity, 'Almaty');
      expect(updated.searchCategoryId, 'cat-1');
      expect(updated.category, same(_category));
      expect(updated.location, same(_location));
    });

    test('clears category and filters when null is passed explicitly', () {
      final state = EquipmentState(
        query: 'bobcat',
        searchCity: 'Almaty',
        searchCategoryId: 'cat-1',
        category: _category,
        location: _location,
      );

      final updated = state.copyWith(
        query: '',
        searchCity: null,
        searchCategoryId: null,
        category: null,
        location: null,
      );

      expect(updated.query, isEmpty);
      expect(updated.searchCity, isNull);
      expect(updated.searchCategoryId, isNull);
      expect(updated.category, isNull);
      expect(updated.location, isNull);
    });
  });
}
