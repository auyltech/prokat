import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_state.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';

class EquipmentMutationNotifier extends Notifier<EquipmentMutationState> {
  late final EquipmentService api;

  @override
  EquipmentMutationState build() {
    api = ref.read(equipmentServiceProvider);

    return const EquipmentMutationState();
  }

  void selectEditEquipment(String equipmentId) {
    state = state.copyWith(editingEquipmentId: equipmentId);
  }

  void clearEditEquipment() {
    state = state.copyWith(editingEquipmentId: null);
  }

  void selectCategory(Category category) {
    state = state.copyWith(category: category);
  }

  void clearCategory() {
    state = state.copyWith(category: null);
  }
}
