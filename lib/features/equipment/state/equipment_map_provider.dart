import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

class EquipmentMapState {
  final Equipment? selectedEquipment;
  final bool isSheetExpanded;

  const EquipmentMapState({
    this.selectedEquipment,
    this.isSheetExpanded = false,
  });

  EquipmentMapState copyWith({
    Equipment? selectedEquipment,
    bool? isSheetExpanded,
  }) {
    return EquipmentMapState(
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      isSheetExpanded: isSheetExpanded ?? this.isSheetExpanded,
    );
  }
}

final equipmentMapProvider =
    StateNotifierProvider<EquipmentMapController, EquipmentMapState>((ref) {
      return EquipmentMapController();
    });

class EquipmentMapController extends StateNotifier<EquipmentMapState> {
  EquipmentMapController() : super(const EquipmentMapState());

  void selectEquipment(Equipment equipment) {
    state = state.copyWith(selectedEquipment: equipment);
  }

  void clearSelection() {
    state = state.copyWith(selectedEquipment: null);
  }

  void toggleSheet(bool expanded) {
    state = state.copyWith(isSheetExpanded: expanded);
  }
}
