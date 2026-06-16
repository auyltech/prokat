import 'package:flutter/material.dart';
import 'package:prokat/features/billing/models/volume_discount_model.dart';

class VolumeDiscountTile extends StatelessWidget {
  final VolumeDiscountModel volumeCase;
  final bool isHighlighted; // Used for "best option" or special discounts

  const VolumeDiscountTile({
    super.key,
    required this.volumeCase,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Pluralization logic for equipment text
    final equipmentText = volumeCase.onlineCount == 1
        ? 'equipment'
        : 'equipments';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Highlighted tile gets a subtle primary tint background, others match the card theme
        color: isHighlighted
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: BoxBorder.all(
          color: isHighlighted
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Left Side: Equipment count text
          Expanded(
            child: Row(
              children: [
                Text(
                  '${volumeCase.onlineCount} ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  equipmentText,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Optional Badge: Shows up if the row is highlighted as a special deal
          if (isHighlighted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'BEST VALUE', // You can change this to a dynamic discount label
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          // Right Side: Rate container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${volumeCase.costPerMinute.toString()} min / hour",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlighted
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
