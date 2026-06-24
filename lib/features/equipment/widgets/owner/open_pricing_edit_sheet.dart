import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/core/widgets/industrial_input_container.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

Future<void> submitPriceEntry(
  BuildContext context,
  WidgetRef ref,
  String equipmentId,
  PriceEntry? priceEntry,
  TextEditingController priceController,
  String selectedRate,
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
    final notifier = ref.read(equipmentProvider.notifier);

    if (priceEntry == null) {
      final res = await notifier.createPriceEntry({
        "equipmentId": equipmentId,
        "price": price,
        "priceRate": selectedRate,
      });

      if (!context.mounted) return;

      if (res) {
        AppSnackBar.show(message: l10n.priceEntryAdded, isSuccess: true);
      } else {
        AppSnackBar.show(message: l10n.failedAddPriceEntry, isError: true);
      }
    } else {
      final res = await notifier.updatePriceEntry({
        "id": priceEntry.id,
        "equipmentId": equipmentId,
        "price": price,
        "priceRate": selectedRate,
      });

      if (!context.mounted) return;

      if (res) {
        AppSnackBar.show(message: l10n.priceEntrySaved);
      } else {
        AppSnackBar.show(message: l10n.failedUpdatePriceEntry, isError: true);
      }
    }
  } catch (e) {
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

  String selectedRate = isEditing
      ? priceEntry.priceRate
      : priceRateOptions.first.value;

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
              IndustrialInputContainer(
                label: l10n.priceRateLabel,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: priceRateOptions.any((e) => e.value == selectedRate)
                        ? selectedRate
                        : priceRateOptions.first.value,
                    dropdownColor: colorScheme.surface,
                    isExpanded: true,
                    icon: Icon(
                      Icons.expand_more_rounded,
                      color: colorScheme.primary,
                    ),
                    items: priceRateOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.value,
                            child: Text(
                              option.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setLocalState(() => selectedRate = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
