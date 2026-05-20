import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AddressEmptyState extends StatelessWidget {
  const AddressEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64),
          const SizedBox(height: 16),
          Text(
            l10n.noEquipmentLocations,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
