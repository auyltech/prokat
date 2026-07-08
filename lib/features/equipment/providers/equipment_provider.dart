import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/search_equipment_notifier.dart';
import 'package:prokat/features/equipment/state/equipment_state.dart';
import '../../../core/api/api_provider.dart';
import '../state/equipment_service.dart';

final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  final api = ref.watch(apiClientProvider);

  return EquipmentService(api);
});

final searchEquipmentProvider =
    StateNotifierProvider<SearchEquipmentNotifier, EquipmentState>((ref) {
      final service = ref.read(equipmentServiceProvider);

      return SearchEquipmentNotifier(service, ref);
    });
