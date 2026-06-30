import 'package:flutter/material.dart';
import 'package:prokat/core/constants/price_rate_options.dart';

class PriceRateSelector extends StatelessWidget {
  final PriceRateOption? initialValue;
  final ValueChanged<PriceRateOption> onChanged;

  const PriceRateSelector({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8.0, // Horizontal space between boxes
      runSpacing: 8.0, // Vertical space between lines if wrapped
      children: priceRateOptions.map((rate) {
        final isSelected = rate == initialValue;

        return ChoiceChip(
          label: Text(rate.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onChanged(rate);
            }
          },
          // Custom styling to make them look like solid wrapped boxes
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
