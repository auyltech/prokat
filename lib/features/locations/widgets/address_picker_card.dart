import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AddressPickerCard extends StatelessWidget {
  final dynamic selectedAddress; // Replace with your Address model
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
      child: Row(
        children: [
          /// Icon Container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 16),

          /// Address Content
          Expanded(
            child: selectedAddress != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.deliverTo, style: theme.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        "${selectedAddress.street}, ${selectedAddress.city}",
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Text(
                    l10n.setDeliveryAddress,
                    style: theme.textTheme.bodyMedium,
                  ),
          ),

          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
