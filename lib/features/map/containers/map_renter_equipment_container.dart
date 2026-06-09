import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/equipment_map_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/map/widgets/equipment_browse_sheet.dart';
import 'package:prokat/features/map/widgets/equipment_details_drawer.dart';
import 'package:prokat/features/map/widgets/map_view.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapRenterEquipmentContainer extends ConsumerWidget {
  const MapRenterEquipmentContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mapState = ref.watch(equipmentMapProvider);
    final equipmentState = ref.watch(equipmentProvider);

    return Scaffold(
      body: Stack(
        children: [
          equipmentState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : equipmentState.error != null
              ? Center(child: Text(l10n.somethingWentWrong))
              : MyMapView(
                  mode: MyMapMode.browseEquipment,
                  equipmentList: equipmentState.renterEquipment,
                ),

          if (mapState.selectedEquipment != null)
            EquipmentDetailsDrawer(equipment: mapState.selectedEquipment!),

          if (mapState.selectedEquipment == null) const EquipmentBrowseSheet(),
        ],
      ),
    );
  }
}
