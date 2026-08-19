import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/equipment/state/equipment_state.dart';
import 'package:prokat/features/equipment/state/search_equipment_notifier.dart';

export 'equipment_dependencies.dart' show equipmentServiceProvider;

final searchEquipmentProvider =
    StateNotifierProvider<SearchEquipmentNotifier, EquipmentState>((ref) {
      final service = ref.read(equipmentServiceProvider);

      return SearchEquipmentNotifier(service, ref);
    });
