import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_map_provider.dart';

Equipment _equipment(String id) {
  return Equipment(
    id: id,
    name: id,
    model: 'model',
    capacity: '1',
    capacityUnit: 'unit',
    status: EquipmentStatus.available,
    isVisible: true,
    prices: const [],
  );
}

void main() {
  group('EquipmentMapState.copyWith', () {
    test('retains selected equipment when it is omitted', () {
      final equipment = _equipment('equipment-1');
      final state = EquipmentMapState(selectedEquipment: equipment);

      final updated = state.copyWith(isSheetExpanded: true);

      expect(updated.selectedEquipment, same(equipment));
      expect(updated.isSheetExpanded, isTrue);
    });

    test('clears selected equipment when null is passed explicitly', () {
      final state = EquipmentMapState(
        selectedEquipment: _equipment('equipment-1'),
      );

      final updated = state.copyWith(selectedEquipment: null);

      expect(updated.selectedEquipment, isNull);
    });
  });

  test('EquipmentMapController.clearSelection drops the current equipment', () {
    final controller = EquipmentMapController();
    addTearDown(controller.dispose);
    controller.selectEquipment(_equipment('equipment-1'));

    controller.clearSelection();

    expect(controller.state.selectedEquipment, isNull);
  });
}
