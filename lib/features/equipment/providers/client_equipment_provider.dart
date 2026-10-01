import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/client_equipment_notifier.dart';

final clientEquipmentProvider =
    AsyncNotifierProvider.family<
      ClientEquipmentNotifier,
      QueryState<Equipment>,
      CatalogGroup
    >(ClientEquipmentNotifier.new);

/// Refreshes every catalog list the UI has already opened.
void refreshLoadedClientEquipment(Ref ref) {
  for (final group in CatalogGroup.values) {
    final provider = clientEquipmentProvider(group);
    if (ref.exists(provider)) {
      unawaited(ref.read(provider.notifier).refresh());
    }
  }
}
