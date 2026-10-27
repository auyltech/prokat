import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/tariff_unit_labels.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PriceRateSelector extends ConsumerWidget {
  final PriceRateOption? initialValue;
  final ValueChanged<PriceRateOption> onChanged;

  const PriceRateSelector({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final languageCode = Localizations.localeOf(context).languageCode;
    final options = buildTariffUnitSelectOptions(
      catalog: catalog,
      languageCode: languageCode,
      legacyLookup: legacyTariffUnitLookupFromL10n(l10n),
      includeCode: initialValue?.value,
    );

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((rate) {
        final isSelected = rate.value == initialValue?.value;

        return ChoiceChip(
          label: Text(rate.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onChanged(rate);
            }
          },
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimary,
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
