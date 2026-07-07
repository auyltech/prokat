import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_notifier.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_state.dart';

final equipmentMutationProvider =
    NotifierProvider<EquipmentMutationNotifier, EquipmentMutationState>(
      EquipmentMutationNotifier.new,
    );
