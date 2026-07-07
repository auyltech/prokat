import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/price_entry_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PricingSection extends ConsumerStatefulWidget {
  final List<PriceEntry> prices;
  final VoidCallback onAdd;
  final Function(PriceEntry) onEdit;
  final Function(PriceEntry) onDelete;
  final int maxRates;

  const PricingSection({
    super.key,
    required this.prices,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.maxRates = 3,
  });

  @override
  ConsumerState<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends ConsumerState<PricingSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);
    final accent = colorScheme.primary;
    final warning = colorScheme.tertiary;

    final bool canAddMore = widget.prices.length < widget.maxRates;

    final isSubmitting = ref
        .watch(equipmentProvider)
        .isActionActive("equipment:price:create");

    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(title: l10n.prices),

              if (isSubmitting)
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              else if (canAddMore)
                IconButton(
                  onPressed: widget.onAdd,
                  icon: Icon(Icons.add, color: accent, size: 24),
                )
              else
                Icon(Icons.lock, color: Colors.grey, size: 18),
            ],
          ),

          /// EMPTY STATE
          if (widget.prices.isEmpty)
            EmptyStateTile(
              title: l10n.noPricesListed,
              icon: Icons.payments_outlined,
              color: warning,
            )
          else
            Column(
              children: widget.prices
                  .map(
                    (p) => PriceEntryTile(
                      priceEntry: p,
                      onEdit: () => widget.onEdit(p),
                      onDelete: () => widget.onDelete(p),
                    ),
                  )
                  .toList(),
            ),

          /// FOOTER (MAX REACHED)
          if (!canAddMore)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Text(
                l10n.allRatingOptionsListed,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ghostGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
