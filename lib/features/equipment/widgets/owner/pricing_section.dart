import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/custom_icon_button.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/price_entry_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/price_entry_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PricingSection extends ConsumerStatefulWidget {
  final List<PriceEntry> prices;
  final String equipmentId;
  final int maxRates;

  const PricingSection({
    super.key,
    required this.prices,
    required this.equipmentId,
    this.maxRates = 3,
  });

  @override
  ConsumerState<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends ConsumerState<PricingSection> {
  Future<void> handleDelete(PriceEntry entry, String equipmentId) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deletePriceEntry),
          content: Text(l10n.deletePriceEntryConfirmation),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final bool result = await ref
        .read(equipmentMutationProvider.notifier)
        .deletePriceEntry(entry, equipmentId);

    AppSnackBar.show(
      message: result ? l10n.priceEntryDeleted : l10n.failedToDeletePriceEntry,
      isSuccess: result,
      isError: !result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final bool canAddMore = widget.prices.length < widget.maxRates;

    final isSubmitting = ref
        .watch(equipmentMutationProvider)
        .isActionActive("equipment:price:create");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionTitle(title: l10n.prices),

            CustomIconButton(
              onPressed: () => PriceEntrySheet.show(
                context,
                equipmentId: widget.equipmentId,
              ),
              icon: canAddMore ? Icons.add : Icons.lock,
              iconColor: canAddMore
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              isLoading: isSubmitting,
            ),
          ],
        ),

        /// EMPTY STATE
        if (widget.prices.isEmpty)
          EmptyStateTile(
            icon: Icons.payments_outlined,
            title: l10n.noPricesListed,
            color: theme.colorScheme.error,
          )
        else
          Column(
            children: widget.prices
                .map(
                  (p) => PriceEntryTile(
                    priceEntry: p,
                    onEdit: () => PriceEntrySheet.show(
                      context,
                      equipmentId: widget.equipmentId,
                      priceEntry: p,
                    ),
                    onDelete: () => handleDelete(p, widget.equipmentId),
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
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Text(
              l10n.allRatingOptionsListed,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
