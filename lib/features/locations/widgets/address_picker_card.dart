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
          Icon(
            Icons.location_on_rounded,
            color: theme.colorScheme.primary,
            size: 32,
          ),

          const SizedBox(width: 12),

          /// Address Content
          Expanded(
            child: Text(
              selectedAddress == null
                  ? l10n.setDeliveryAddress
                  : "${selectedAddress.street}, ${selectedAddress.city}",
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
