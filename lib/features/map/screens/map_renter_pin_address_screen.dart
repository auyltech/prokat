import 'package:flutter/material.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/map/containers/map_container.dart';
import 'package:prokat/features/map/containers/map_renter_pin_address_container.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapRenterPinAddressScreen extends StatelessWidget {
  const MapRenterPinAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MapContainer(
      title: l10n.setDeliveryAddress,
      redirectRoute: "${AppRoutes.clientCreateAddress}?service=address",
      redirectLabel: l10n.back,
      mobileMap: const MapRenterPinAddressContainer(),
    );
  }
}
