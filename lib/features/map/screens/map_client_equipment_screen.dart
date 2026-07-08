import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/map/containers/map_container.dart';
import 'package:prokat/features/map/containers/map_client_equipment_container.dart';
import 'package:prokat/l10n/app_localizations.dart';
import '../../../core/router/app_routes.dart';

class MapClientEquipmentScreen extends ConsumerStatefulWidget {
  const MapClientEquipmentScreen({super.key});

  @override
  ConsumerState<MapClientEquipmentScreen> createState() =>
      _MapRenterEquipmentScreenState();
}

class _MapRenterEquipmentScreenState
    extends ConsumerState<MapClientEquipmentScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(clientEquipmentProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MapContainer(
      title: l10n.equipmentMap,
      redirectRoute: AppRoutes.searchList,
      redirectLabel: l10n.viewEquipmentList,
      mobileMap: const MapClientEquipmentContainer(),
    );
  }
}
