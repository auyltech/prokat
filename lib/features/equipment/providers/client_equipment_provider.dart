import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/client_equipment_notifier.dart';
import 'package:riverpod/riverpod.dart';

final clientEquipmentProvider =
    AsyncNotifierProvider<ClientEquipmentNotifier, QueryState<Equipment>>(
      ClientEquipmentNotifier.new,
    );
