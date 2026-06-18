import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_picker_component.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/core/widgets/time_picker_component.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/utils/date_time.dart';
import 'package:prokat/features/categories/widgets/user_category_selector.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

class CreateRequestForm extends ConsumerStatefulWidget {
  const CreateRequestForm({super.key});

  @override
  ConsumerState<CreateRequestForm> createState() => _CreateRequestFormState();
}

class _CreateRequestFormState extends ConsumerState<CreateRequestForm> {
  final capacityController = TextEditingController();
  final rateController = TextEditingController();
  final commentController = TextEditingController();

  @override
  void dispose() {
    capacityController.dispose();
    rateController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    final selectedCategory = ref.read(categoriesProvider).selectedCategory;

    if (selectedCategory == null) {
      AppSnackBar.show(
        context,
        message: "Please select category",
        isError: true,
      );
      return;
    }

    final requestNotifier = ref.read(requestProvider.notifier);

    final success = await requestNotifier.createRequest(
      categoryId: selectedCategory.id,
      capacity: capacityController.text.trim(),
      offeredRate: parseNullableInt(rateController.text.trim()) ?? 0,
      comment: commentController.text.trim(),
    );

    if (mounted) {
      AppSnackBar.show(
        context,
        message: success ? l10n.requestCreated : "Failed to create request",
        isSuccess: success,
        isError: !success,
      );
    }
  }

  void _openAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SelectAddressSheet(service: "address"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(locationProvider);
    final categoriesState = ref.watch(categoriesProvider);

    final requestState = ref.watch(requestProvider);
    final requestNotifier = ref.read(requestProvider.notifier);

    ref.listen(locationProvider, (previous, next) {
      final address = next.selectedAddress;

      if (address?.id != null) {
        ref.read(requestProvider.notifier).selectLocation(address!);
      }
    });

    ref.listen(userProfileProvider, (previous, next) {
      final profileCategoryId = next.userProfile?.selectedCategoryId;

      final foundCategory = categoriesState.categories
          .where((item) => item.id == profileCategoryId)
          .firstOrNull;

      if (profileCategoryId != null && foundCategory != null) {
        ref.read(requestProvider.notifier).selectCategory(foundCategory);
      }
    });

    // const int daysRange = 7;

    // final DateTime now = DateTime.now();
    // Strip time to avoid mid-day edge-case bugs with minimum/maximum dates
    // final DateTime today = DateTime(now.year, now.month, now.day);
    // final DateTime maxRangeDate = today.add(const Duration(days: daysRange));

    // Safely resolve the initial date
    // DateTime initialDate = requestState.selectedDate ?? initialTargetDateTime;

    // if (initialDate.isBefore(today)) {
    //   initialDate = today;
    // } else if (initialDate.isAfter(maxRangeDate)) {
    //   initialDate = maxRangeDate;
    // }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const UserCategorySelector(mode: "create_request"),

        const SizedBox(height: 24),

        SectionTitle(title: l10n.deliveryLocation),

        const SizedBox(height: 6),

        AddressPickerCard(
          selectedAddress: locationState.selectedAddress,
          onTap: () => _openAddressSheet(context),
        ),

        const SizedBox(height: 24),

        SectionTitle(title: l10n.equipmentSpecs),

        const SizedBox(height: 6),

        InputField(
          label: l10n.requiredCapacity,
          controller: capacityController,
          hint: l10n.capacityHint,
          icon: Icons.propane_outlined,
          suffixText: "M3",
        ),

        const SizedBox(height: 12),

        InputField(
          label: l10n.offeredRate,
          controller: rateController,
          hint: l10n.offeredRateHint,
          icon: Icons.payments_outlined,
        ),

        const SizedBox(height: 12),

        InputField(
          label: l10n.comments,
          controller: commentController,
          hint: l10n.additionalDetails,
          icon: Icons.chat_bubble_outline_rounded,
        ),

        const SizedBox(height: 12),

        DatePickerComponent(
          daysRange: 7, // Pass your dynamic 'x' range here
          isRequired: true, // Shows indicator text
          selectedDate: requestState.selectedDate ?? initialTargetDateTime,
          onDateSelected: (date) {
            requestNotifier.setDate(date);
          },
        ),

        TimePickerComponent(
          slotLengthMinutes: 30, // 30 minute blocks
          startHour: 9, // Start at 09:00
          endHour: 17, // End at 17:00
          isRequired: true,
          selectedDateTime: requestState.selectedTime ?? initialTargetDateTime,
          onTimeSelected: (updatedDateTime) {
            requestNotifier.setTime(
              updatedDateTime,
            ); // This emits a full DateTime object
          },
        ),

        const SizedBox(height: 40),

        if (requestState.error != null) ...[
          Text(requestState.error!),
          SizedBox(height: 8),
        ],

        PrimaryButton(
          label: l10n.create,
          isLoading: requestState.isSubmitting,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
