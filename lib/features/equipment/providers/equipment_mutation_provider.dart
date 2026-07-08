import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_notifier.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_state.dart';

final equipmentMutationProvider =
    StateNotifierProvider<EquipmentMutationNotifier, EquipmentMutationState>((
      ref,
    ) {
      final api = ref.read(equipmentServiceProvider);

      return EquipmentMutationNotifier(api: api, ref: ref);
    });
