import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/map/containers/map_container.dart';
import 'package:prokat/features/map/containers/map_renter_equipment_container.dart';
import 'package:prokat/l10n/app_localizations.dart';
import '../../../core/router/app_routes.dart';

class MapRenterEquipmentScreen extends ConsumerStatefulWidget {
  const MapRenterEquipmentScreen({super.key});

  @override
  ConsumerState<MapRenterEquipmentScreen> createState() =>
      _MapRenterEquipmentScreenState();
}

class _MapRenterEquipmentScreenState
    extends ConsumerState<MapRenterEquipmentScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(equipmentProvider.notifier).getClientEquipment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MapContainer(
      title: l10n.equipmentMap,
      redirectRoute: AppRoutes.searchList,
      redirectLabel: l10n.viewEquipmentList,
      mobileMap: const MapRenterEquipmentContainer(),
    );
  }
}
