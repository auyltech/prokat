import 'package:flutter/material.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';

class PriceEntryTile extends StatelessWidget {
  final PriceEntry price;
  final VoidCallback onEdit;

  const PriceEntryTile({super.key, required this.price, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          /// PRICE INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.priceRate.label, // e.g. "Per Hour"
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${price.price} ₸",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// EDIT ACTION
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded, color: accent, size: 20),
          ),
        ],
      ),
    );
  }
}
