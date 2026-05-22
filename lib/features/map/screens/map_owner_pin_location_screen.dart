import 'package:flutter/material.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/map/containers/map_container.dart';
import 'package:prokat/features/map/containers/map_owner_pin_location_container.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapOwnerPinLocationScreen extends StatelessWidget {
  final String equipmentId;

  const MapOwnerPinLocationScreen({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MapContainer(
      title: l10n.setEquipmentLocation,
      redirectRoute: "${AppRoutes.ownerAddressCreate}?service=equipment",
      redirectLabel: l10n.backToEquipment,
      mobileMap: MapOwnerPinLocationContainer(equipmentId: equipmentId),
    );
  }
}
