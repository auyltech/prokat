import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AddressPickerCard extends StatelessWidget {
  final LocationModel? selectedAddress; // Replace with your Address model
  final VoidCallback onTap;

  const AddressPickerCard({
    super.key,
    required this.selectedAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: BaseTile(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        // decoration: BoxDecoration(
        //   color: theme.cardColor,
        //   borderRadius: BorderRadius.circular(16),
        //   border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        // ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: theme.colorScheme.primary,
              size: 32,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedAddress == null
                        ? l10n.setDeliveryAddress
                        : "Address",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    selectedAddress != null
                        ? "${selectedAddress?.street}, ${selectedAddress?.city}"
                        : "select",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            Column(
              children: [
                if (selectedAddress == null)
                  Text("*", style: TextStyle(color: theme.colorScheme.error)),

                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
