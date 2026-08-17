import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

// Not used, viewing equipment on map is currently disabled
class EquipmentMapState {
  static const _notProvided = Object();

  final Equipment? selectedEquipment;
  final bool isSheetExpanded;

  const EquipmentMapState({
    this.selectedEquipment,
    this.isSheetExpanded = false,
  });

  EquipmentMapState copyWith({
    Object? selectedEquipment = _notProvided,
    bool? isSheetExpanded,
  }) {
    assert(
      identical(selectedEquipment, _notProvided) ||
          selectedEquipment is Equipment?,
      'selectedEquipment must be an Equipment or null',
    );

    return EquipmentMapState(
      selectedEquipment: identical(selectedEquipment, _notProvided)
          ? this.selectedEquipment
          : selectedEquipment as Equipment?,
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
