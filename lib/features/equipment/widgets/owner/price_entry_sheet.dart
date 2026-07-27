import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/bookings/widgets/price_rate_selector.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PriceEntrySheet extends ConsumerStatefulWidget {
  final String equipmentId;
  final PriceEntry? priceEntry;

  const PriceEntrySheet({
    super.key,
    required this.equipmentId,
    this.priceEntry,
  });

  static Future<void> show(
    BuildContext context, {
    required String equipmentId,
    PriceEntry? priceEntry,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows sheet to wrap its content height dynamically
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return PriceEntrySheet(
          equipmentId: equipmentId,
          priceEntry: priceEntry,
        );
      },
    );
  }

  @override
  ConsumerState<PriceEntrySheet> createState() => _PriceEntrySheetState();
}

class _PriceEntrySheetState extends ConsumerState<PriceEntrySheet> {
  late final TextEditingController _priceController;
  late PriceRateOption _selectedRate;
  bool _isSubmitting = false;

  Future<void> submitPriceEntry(AppLocalizations l10n) async {
    if (_isSubmitting) return;

    final price = int.tryParse(_priceController.text.trim());

    if (price == null) {
      AppSnackBar.show(message: l10n.pleaseEnterValidPrice);
      return;
    }

    if (price <= 0) {
      AppSnackBar.show(message: l10n.priceMustBePositive);
      return;
    }

    if (price > 100000) {
      AppSnackBar.show(message: l10n.priceMaximumExceeded);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(equipmentMutationProvider.notifier);

      if (!mounted) return;
      Navigator.pop(context);

      if (widget.priceEntry == null) {
        final result = await notifier.createPriceEntry(
          price,
          _selectedRate,
          widget.equipmentId,
        );

        AppSnackBar.show(
          message: result.success
              ? l10n.priceEntryAdded
              : l10n.failedAddPriceEntry,
          isSuccess: result.success,
          isError: !result.success,
        );
      } else {
        final result = await notifier.updatePriceEntry(
          PriceEntry(
            id: widget.priceEntry!.id,
            price: price,
            priceRate: _selectedRate,
          ),
          widget.equipmentId,
        );

        if (!mounted) return;
        Navigator.pop(context);

        AppSnackBar.show(
          message: result.success
              ? l10n.priceEntrySaved
              : l10n.failedUpdatePriceEntry,
          isSuccess: result.success,
          isError: !result.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnackBar.show(message: l10n.failedSavePriceEntry, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final isEditing = widget.priceEntry != null;

    _priceController = TextEditingController(
      text: isEditing ? widget.priceEntry?.price.toString() : "",
    );

    _selectedRate = isEditing
        ? widget.priceEntry!.priceRate
        : priceRateOptions.first;
  }

  @override
  void dispose() {
    // FIXED: Frees up OS controller threads to keep your memory profiles clean
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.priceEntry != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 12, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isEditing ? l10n.editRate : l10n.newRate,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          /// 1. PRICE INPUT
          InputField(
            label: l10n.priceKZT,
            controller: _priceController,
            hint: "10,000 KZT",
            isNumeric: true,
          ),
          const SizedBox(height: 16),

          /// 2. RATE TYPE SELECTOR
          PriceRateSelector(
            initialValue: _selectedRate,
            // FIXED: Using standard setState to safely refresh stateful configurations
            onChanged: (val) {
              setState(() => _selectedRate = val);
            },
          ),
          const SizedBox(height: 24),

          /// 3. ACTION SUBMIT BUTTON
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _isSubmitting
                  ? "Saving..."
                  : (isEditing ? l10n.save : l10n.add),
              // FIXED: Added submission pipeline execution
              onPressed: _isSubmitting ? null : () => submitPriceEntry(l10n),
            ),
          ),
        ],
      ),
    );
  }
}
