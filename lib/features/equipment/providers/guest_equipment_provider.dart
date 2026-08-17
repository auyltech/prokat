import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/guest_equipment_notifier.dart';

export 'equipment_provider.dart' show equipmentServiceProvider;

final guestEquipmentProvider =
    AsyncNotifierProvider<GuestEquipmentNotifier, QueryState<Equipment>>(
      GuestEquipmentNotifier.new,
    );
