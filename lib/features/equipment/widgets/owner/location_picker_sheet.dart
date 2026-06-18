import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/equipment/models/equipment_location.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LocationPickerSheet extends StatelessWidget {
  final List<EquipmentLocation> locations;

  const LocationPickerSheet({super.key, required this.locations});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final previewLocations = locations.take(2).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectEquipmentLocation,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// SAVED LOCATIONS
            if (previewLocations.isNotEmpty)
              ...previewLocations.map(
                (loc) => ListTile(
                  leading: const Icon(Icons.location_on_rounded),
                  title: Text(loc.city ?? ""),
                  subtitle: Text(loc.street),
                  onTap: () {
                    Navigator.pop(context, loc);
                  },
                ),
              ),

            if (previewLocations.isNotEmpty) const SizedBox(height: 8),

            /// VIEW ALL
            if (locations.length > 2)
              ListTile(
                leading: const Icon(Icons.list_rounded),
                title: Text(l10n.viewAllLocations),
                onTap: () {
                  context.push(AppRoutes.ownerAddresses);
                },
              ),

            const Divider(height: 32),

            /// ADD MANUALLY
            ListTile(
              leading: const Icon(Icons.add_location_alt_rounded),
              title: Text(l10n.addAddressManually),
              onTap: () {
                context.push(AppRoutes.ownerAddressCreate);
              },
            ),

            /// SET ON MAP
            ListTile(
              leading: const Icon(Icons.map_rounded),
              title: Text(l10n.setOnMap),
              onTap: () {
                context.push(AppRoutes.ownerAddressMap);
              },
            ),
          ],
        ),
      ),
    );
  }
}
