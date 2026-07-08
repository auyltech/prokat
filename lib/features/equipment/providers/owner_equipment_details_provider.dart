import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/owner_equipment_details_notifier.dart';
import 'package:riverpod/riverpod.dart';

final ownerEquipmentDetailsProvider =
    AsyncNotifierProviderFamily<
      OwnerEquipmentDetailsNotifier,
      Equipment,
      String
    >(OwnerEquipmentDetailsNotifier.new);
