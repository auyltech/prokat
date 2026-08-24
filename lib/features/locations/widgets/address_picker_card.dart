import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AddressPickerCard extends StatelessWidget {
  final LocationModel? selectedAddress;
  final VoidCallback onTap;
  final bool? isRequired;

  const AddressPickerCard({
    super.key,
    required this.selectedAddress,
    required this.onTap,
    this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color:
            Colors.transparent, // Ensures the entire row area remains clickable
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.mapPin,
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Label and required validation indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.deliveryLocation,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRequired == true)
                        Text(
                          l10n.requiredHint,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Bottom Row: Extracted address string value and target chevron
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedAddress != null
                              ? "${selectedAddress?.street}, ${selectedAddress?.city}"
                              : l10n.selectValue,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: selectedAddress != null
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
