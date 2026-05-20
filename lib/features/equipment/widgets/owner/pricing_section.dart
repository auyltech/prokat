import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/widgets/owner/price_entry_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PricingSection extends StatelessWidget {
  final List<PriceEntry> prices;
  final VoidCallback onAdd;
  final Function(PriceEntry) onEdit;
  final int maxRates;

  const PricingSection({
    super.key,
    required this.prices,
    required this.onAdd,
    required this.onEdit,
    this.maxRates = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);
    final accent = colorScheme.primary;
    final warning = colorScheme.tertiary;

    final bool canAddMore = prices.length < maxRates;

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

              if (canAddMore)
                IconButton(
                  onPressed: onAdd,
                  icon: Icon(Icons.add, color: accent, size: 24),
                )
              else
                Icon(Icons.lock, color: Colors.grey, size: 18),
            ],
          ),

          /// EMPTY STATE
          if (prices.isEmpty)
            EmptyStateTile(
              title: l10n.noPricesListed,
              icon: Icons.payments_outlined,
              color: warning,
            )
          else
            Column(
              children: prices
                  .map((p) => PriceEntryTile(price: p, onEdit: () => onEdit(p)))
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
