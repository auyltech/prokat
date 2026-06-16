import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/billing/models/pricing_tier_model.dart';

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

    return GestureDetector(
      onTap: onSelect,
      child: Container(
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
              pricingTier.name,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            Text(
              pricingTier.label,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "${formatPrice(pricingTier.price)} KZT",
              style: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
