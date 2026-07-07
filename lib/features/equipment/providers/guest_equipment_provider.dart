import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/state/guest_equipment_notifier.dart';

final equipmentServiceProvider = Provider<EquipmentService>((ref) {
  final api = ref.watch(apiClientProvider);

  return EquipmentService(api);
});

final guestEquipmentProvider =
    AsyncNotifierProvider<GuestEquipmentNotifier, QueryState<Equipment>>(
      GuestEquipmentNotifier.new,
    );
