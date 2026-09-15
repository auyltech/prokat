import 'package:flutter/material.dart';
import 'package:prokat/features/billing/models/pricing_tier_model.dart';
import 'package:prokat/features/billing/utils/billing_display.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PriceTierTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onSelect;
  final PricingTierModel pricingTier;

  const PriceTierTile({
    super.key,
    required this.isSelected,
    required this.onSelect,
    required this.pricingTier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final titleColor = isSelected ? Colors.white : theme.colorScheme.onSurface;
    final minutesColor = isSelected ? Colors.white : theme.colorScheme.primary;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              packageTitle(pricingTier, l10n),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              packageMinutesLabel(pricingTier, l10n),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: minutesColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
