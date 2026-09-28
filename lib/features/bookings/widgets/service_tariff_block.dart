import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ServiceTariffBlock extends StatelessWidget {
  const ServiceTariffBlock({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final PriceEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;
    final priceText =
        '${formatPrice(entry.price)} ${getPriceRate(entry.priceRate, l10n: l10n)}';
    final serviceName = savedTariffTitle(entry, l10n);
    final label = serviceName == null ? priceText : '$priceText — $serviceName';

    return Material(
      color: selected ? primary : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? primary
              : theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
