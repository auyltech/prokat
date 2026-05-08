import 'package:flutter/material.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/map/containers/map_container.dart';
import 'package:prokat/features/map/containers/map_renter_pin_address_container.dart';

class MapRenterPinAddressScreen extends StatelessWidget {
  const MapRenterPinAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MapContainer(
      title: "Set Delivery Address",
      redirectRoute: "${AppRoutes.ownerAddressCreate}?service=address",
      redirectLabel: "Back",
      mobileMap: MapRenterPinAddressContainer(),
    );
  }
}
