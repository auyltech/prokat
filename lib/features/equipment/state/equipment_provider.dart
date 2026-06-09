import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/equipment_notifier.dart';
import 'package:prokat/features/equipment/state/equipment_state.dart';
import '../../../core/providers/api_provider.dart';
import 'equipment_service.dart';

final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  final api = ref.watch(apiClientProvider);

  return EquipmentService(api);
});

final equipmentProvider =
    StateNotifierProvider<EquipmentNotifier, EquipmentState>((ref) {
      final service = ref.read(equipmentServiceProvider);
      return EquipmentNotifier(service);
    });
