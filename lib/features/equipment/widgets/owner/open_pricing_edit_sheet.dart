import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/core/widgets/industrial_input_container.dart';
import 'package:prokat/features/bookings/widgets/price_rate_selector.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

Future<void> submitPriceEntry(
  BuildContext context,
  WidgetRef ref,
  String equipmentId,
  PriceEntry? priceEntry,
  TextEditingController priceController,
  PriceRateOption selectedRate,
  AppLocalizations l10n,
) async {
  final price = int.tryParse(priceController.text.trim());

  // 1. Basic price parsing check
  if (price == null) {
    AppSnackBar.show(message: l10n.pleaseEnterValidPrice);
    return;
  }

  // 2. Enforce positive price and maximum limit (e.g., 100,000)
  if (price <= 0) {
    AppSnackBar.show(
      message: "Price must be greater than zero",
    ); // Use l10n if available
    return;
  }

  if (price > 100000) {
    AppSnackBar.show(
      message: "Price cannot exceed 100,000",
    ); // Use l10n if available
    return;
  }

  // Validation passed, close sheet and proceed
  Navigator.pop(context);

  try {
    final notifier = ref.read(equipmentMutationProvider.notifier);

    if (priceEntry == null) {
      final result = await notifier.createPriceEntry(
        price,
        selectedRate,
        equipmentId,
      );

      if (!context.mounted) return;

      AppSnackBar.show(
        message: result.success
            ? l10n.priceEntryAdded
            : l10n.failedAddPriceEntry,
        isSuccess: result.success,
        isError: !result.success,
      );
    } else {
      final result = await notifier.updatePriceEntry(
        PriceEntry(id: priceEntry.id, price: price, priceRate: selectedRate),
        equipmentId,
      );

      AppSnackBar.show(
        message: result.success
            ? l10n.priceEntrySaved
            : l10n.failedUpdatePriceEntry,
        isSuccess: result.success,
        isError: !result.success,
      );
    }
  } catch (error) {
    if (context.mounted) {
      AppSnackBar.show(message: l10n.failedSavePriceEntry, isError: true);
    }
  }
}

void openPricingEditSheet(
  BuildContext context,
  WidgetRef ref,
  String equipmentId, {
  PriceEntry? priceEntry,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final l10n = AppLocalizations.of(context)!;

  final isEditing = priceEntry != null;

  final priceController = TextEditingController(
    text: isEditing ? priceEntry.price.toString() : "",
  );

  PriceRateOption selectedRate = isEditing
      ? priceEntry.priceRate
      : priceRateOptions.first;

  showEditSheet(
    context: context,
    sheet: EditSheet(
      title: isEditing ? l10n.editRate : l10n.newRate,
      buttonText: isEditing ? l10n.save : l10n.add,
      onSubmit: () => submitPriceEntry(
        context,
        ref,
        equipmentId,
        priceEntry,
        priceController,
        selectedRate,
        l10n,
      ),
      child: StatefulBuilder(
        builder: (context, setLocalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 1. PRICE INPUT
              IndustrialInputContainer(
                label: l10n.priceKZT,
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // Prevents negative signs (-) and decimals (.)
                    LengthLimitingTextInputFormatter(
                      6,
                    ), // Prevents typing numbers longer than 6 digits (e.g. 999999)
                  ],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// 2. RATE TYPE SELECTOR
              PriceRateSelector(
                initialValue: selectedRate,
                onChanged: (val) => setLocalState(() => selectedRate = val),
              ),
            ],
          );
        },
      ),
    ),
  );
}
