import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';

final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  final api = ref.watch(apiClientProvider);

  return EquipmentService(api);
});
