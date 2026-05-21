import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/edit_sheet.dart';
import 'package:prokat/core/widgets/industrial_input_container.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';

Future<void> submitPriceEntry(
  BuildContext context,
  WidgetRef ref,
  String equipmentId,
  PriceEntry? priceEntry,
  TextEditingController priceController,
  TextEditingController serviceTimeController,
  String selectedRate,
) async {
  final price = int.tryParse(priceController.text.trim());
  final serviceTime = int.tryParse(serviceTimeController.text.trim()) ?? 0;

  if (price == null) {
    AppSnackBar.show(context, message: "Please enter a valid price");

    return;
  }

  Navigator.pop(context);

  try {
    final notifier = ref.read(equipmentProvider.notifier);

    if (priceEntry == null) {
      final res = await notifier.createPriceEntry({
        "equipmentId": equipmentId,
        "price": price,
        "priceRate": selectedRate,
        "serviceTime": serviceTime,
      });

      if (!context.mounted) return;

      if (res) {
        AppSnackBar.show(
          context,
          message: "Price entry added",
          isSuccess: true,
        );
      } else {
        AppSnackBar.show(
          context,
          message: "Failed to add price entry",
          isError: true,
        );
      }
    } else {
      final res = await notifier.updatePriceEntry({
        "id": priceEntry.id,
        "equipmentId": equipmentId,
        "price": price,
        "priceRate": selectedRate,
        "serviceTime": serviceTime,
      });

      if (!context.mounted) return;

      if (res) {
        AppSnackBar.show(context, message: "Price entry saved");
      } else {
        AppSnackBar.show(
          context,
          message: "Failed to update price entry",
          isError: true,
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      AppSnackBar.show(
        context,
        message: "Failed to save price entry",
        isError: true,
      );
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

  final isEditing = priceEntry != null;

  final priceController = TextEditingController(
    text: isEditing ? priceEntry.price.toString() : "",
  );

  final serviceTimeController = TextEditingController(
    text: isEditing ? priceEntry.serviceTime.toString() : "",
  );

  String selectedRate = isEditing
      ? priceEntry.priceRate
      : priceRateOptions.first.value;

  showEditSheet(
    context: context,
    sheet: EditSheet(
      title: isEditing ? "Edit Rate" : "New Rate",
      buttonText: isEditing ? "Save" : "Add",
      onSubmit: () => submitPriceEntry(
        context,
        ref,
        equipmentId,
        priceEntry,
        priceController,
        serviceTimeController,
        selectedRate,
      ),
      child: StatefulBuilder(
        builder: (context, setLocalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 1. PRICE INPUT
              IndustrialInputContainer(
                label: "Price (₸)",
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
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
                label: "Price Rate",
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
