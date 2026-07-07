import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/owner_equipment_notifier.dart';

final ownerEquipmentProvider =
    AsyncNotifierProvider<OwnerEquipmentNotifier, QueryState<Equipment>>(
      OwnerEquipmentNotifier.new,
    );
