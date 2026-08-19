import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_state.dart';

void main() {
  const category = Category(id: 'category-1', name: 'Crane', sortIndex: 1);

  group('EquipmentMutationState.copyWith', () {
    test('retains nullable selections when they are omitted', () {
      const state = EquipmentMutationState(
        editingEquipmentId: 'equipment-1',
        category: category,
      );

      final updated = state.copyWith(activeActions: const {});

      expect(updated.editingEquipmentId, 'equipment-1');
      expect(updated.category, same(category));
    });

    test('clears nullable selections when null is passed explicitly', () {
      const state = EquipmentMutationState(
        editingEquipmentId: 'equipment-1',
        category: category,
      );

      final updated = state.copyWith(editingEquipmentId: null, category: null);

      expect(updated.editingEquipmentId, isNull);
      expect(updated.category, isNull);
    });
  });
}
