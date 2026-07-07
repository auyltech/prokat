import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';

class PriceEntryTile extends ConsumerStatefulWidget {
  final PriceEntry priceEntry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PriceEntryTile({
    super.key,
    required this.priceEntry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<PriceEntryTile> createState() => _PriceEntryTileState();
}

class _PriceEntryTileState extends ConsumerState<PriceEntryTile> {
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
                  widget.priceEntry.priceRate.label, // e.g. "Per Hour"
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${widget.priceEntry.price} ₸",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// EDIT ACTION
          if (ref
              .watch(equipmentProvider)
              .isActionActive("equipment:price:update:${widget.priceEntry.id}"))
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            )
          else
            IconButton(
              onPressed: widget.onEdit,
              icon: Icon(Icons.edit_rounded, color: accent, size: 20),
            ),

          if (ref
              .watch(equipmentProvider)
              .isActionActive("equipment:price:delete:${widget.priceEntry.id}"))
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            )
          else
            IconButton(
              onPressed: widget.onDelete,
              icon: Icon(Icons.delete, color: Colors.red, size: 20),
            ),
        ],
      ),
    );
  }
}
