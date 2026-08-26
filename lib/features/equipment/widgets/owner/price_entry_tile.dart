import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          /// PRICE INFO
          Expanded(
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.priceEntry.price} ₸",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  getPriceRate(widget.priceEntry.priceRate, l10n: l10n),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          /// EDIT ACTION
          if (ref
              .watch(equipmentMutationProvider)
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
              .watch(equipmentMutationProvider)
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
