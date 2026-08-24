import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_map_provider.dart';
import 'package:prokat/features/map/widgets/equipment_browse_sheet.dart';
import 'package:prokat/features/map/widgets/equipment_details_drawer.dart';
import 'package:prokat/features/map/widgets/map_view.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapClientEquipmentContainer extends ConsumerWidget {
  const MapClientEquipmentContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final mapState = ref.watch(equipmentMapProvider);
    final equipmentAsync = ref.watch(clientEquipmentProvider);

    final equipment = equipmentAsync.value?.items ?? [];

    return Scaffold(
      body: Stack(
        children: [
          if (equipmentAsync.isLoading && equipment.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (equipmentAsync.hasError)
            Center(child: Text(l10n.somethingWentWrong))
          else
            MyMapView(
              mode: MyMapMode.browseEquipment,
              equipmentList: equipment,
            ),

          if (mapState.selectedEquipment != null)
            EquipmentDetailsDrawer(equipment: mapState.selectedEquipment!),

          if (mapState.selectedEquipment == null) const EquipmentBrowseSheet(),
        ],
      ),
    );
  }
}
