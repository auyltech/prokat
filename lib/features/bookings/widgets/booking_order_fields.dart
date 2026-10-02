import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Tariffs a client can book: owner rows with a price.
List<PriceEntry> bookablePrices(Equipment equipment) {
  return equipment.prices.where((entry) => entry.price > 0).toList();
}

bool bookingIsEquipmentGroup(Equipment equipment) {
  return equipment.category?.catalogGroup == CatalogGroup.equipment;
}

String bookingTariffLabel(PriceEntry entry, AppLocalizations l10n) {
  final priceText =
      '${formatPrice(entry.price)} ${getPriceRate(entry.priceRate, l10n: l10n)}';
  final serviceName = savedTariffTitle(entry, l10n);
  if (serviceName == null) return priceText;
  return '$priceText — $serviceName';
}

/// Address, tariff, schedule, comment and submit — shared by both booking screens.
class BookingOrderFields extends ConsumerWidget {
  final bool isEquipmentGroup;
  final LocationModel? address;
  final Future<LocationModel?> Function() openAddressSheet;
  final ValueChanged<LocationModel> onAddressChanged;
  final List<PriceEntry> prices;
  final PriceEntry? selectedPrice;
  final ValueChanged<PriceEntry> onPriceChanged;
  final JobScheduleMode scheduleMode;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final String locale;
  final VoidCallback onScheduled;
  final VoidCallback onAsap;
  final Future<void> Function() onPickDate;
  final Future<void> Function() onPickTime;
  final TextEditingController commentController;
  final ValueChanged<String>? onCommentChanged;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onSubmit;

  const BookingOrderFields({
    super.key,
    required this.isEquipmentGroup,
    required this.address,
    required this.openAddressSheet,
    required this.onAddressChanged,
    required this.prices,
    required this.selectedPrice,
    required this.onPriceChanged,
    required this.scheduleMode,
    required this.selectedDate,
    required this.selectedTime,
    required this.locale,
    required this.onScheduled,
    required this.onAsap,
    required this.onPickDate,
    required this.onPickTime,
    required this.commentController,
    this.onCommentChanged,
    required this.canSubmit,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final singleTariff = prices.length == 1;
    final tariffValue = singleTariff ? prices.first : selectedPrice;
    final addressLabel = address == null
        ? null
        : formatLocationModel(ref, context, address!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimens.s12$md),
        AppDropdownField<LocationModel>(
          title: l10n.bookingDestinationTitle,
          hint: isEquipmentGroup
              ? l10n.bookingDestinationEquipmentHint
              : l10n.bookingDestinationMachineryHint,
          isRequired: true,
          sheetTitle: l10n.selectAddress,
          value: address,
          selectedLabel: addressLabel,
          openCustomSheet: openAddressSheet,
          onChanged: onAddressChanged,
        ),
        const SizedBox(height: AppDimens.s16$base),
        AppDropdownField<PriceEntry>(
          title: singleTariff
              ? l10n.bookingTariffSingleTitle
              : l10n.bookingTariffSelectTitle,
          hint: l10n.bookingTariffSelectHint,
          isRequired: !singleTariff,
          enabled: !singleTariff,
          sheetTitle: l10n.bookingTariffSelectTitle,
          value: tariffValue,
          selectedLabel: tariffValue == null
              ? null
              : bookingTariffLabel(tariffValue, l10n),
          options: [
            for (final entry in prices)
              DropdownOption(
                value: entry,
                label: bookingTariffLabel(entry, l10n),
              ),
          ],
          onChanged: onPriceChanged,
        ),
        const SizedBox(height: AppDimens.s20$lg),
        JobScheduleSection(
          mode: scheduleMode,
          requiredHint: l10n.requestRequiredHint,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          locale: locale,
          onScheduled: onScheduled,
          onAsap: onAsap,
          onPickDate: onPickDate,
          onPickTime: onPickTime,
        ),
        const SizedBox(height: AppDimens.s20$lg),
        AppTextArea(
          title: l10n.bookingOrderCommentTitle,
          hint: l10n.requestCommentHint,
          controller: commentController,
          minLines: 2,
          maxLines: 4,
          onChanged: onCommentChanged,
        ),
        const SizedBox(height: AppDimens.s32$xxl),
        AppElevatedButton(
          title: l10n.createOrder,
          onTap: (!canSubmit || submitting) ? null : onSubmit,
          isLoading: submitting,
        ),
      ],
    );
  }
}
