import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_time_button.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
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

    if (success && mounted) {
      AppSnackBar.show(context, message: l10n.requestCreated, isSuccess: true);
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
    final theme = Theme.of(context);
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

        SectionTitle(title: l10n.dateAndTime),

        const SizedBox(height: 6),

        Row(
          children: [
            Expanded(
              child: DateTimeButton(
                icon: Icons.calendar_today_rounded,
                label: requestState.selectedDate == null
                    ? l10n.selectDate
                    : DateFormat(
                        'MMM dd, yyyy',
                      ).format(requestState.selectedDate!),
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      height: 300,
                      color: theme.scaffoldBackgroundColor,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        // 1. Safe calculation: use the maximum of the two dates to prevent underflow
                        initialDateTime:
                            (requestState.selectedDate ?? initialTargetDateTime)
                                .isBefore(DateTime.now())
                            ? DateTime.now()
                            : (requestState.selectedDate ??
                                  initialTargetDateTime),
                        minimumDate: DateTime.now(),
                        maximumDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        onDateTimeChanged: (date) {
                          requestNotifier.setDate(date);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: DateTimeButton(
                icon: Icons.access_time_rounded,
                label: requestState.selectedTime == null
                    ? l10n.selectTime
                    : DateFormat.jm().format(requestState.selectedTime!),
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      height: 300,
                      color: theme.scaffoldBackgroundColor,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: false,
                        initialDateTime:
                            requestState.selectedTime ?? initialTargetDateTime,
                        onDateTimeChanged: (time) {
                          requestNotifier.setTime(time);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        PrimaryButton(
          label: l10n.create,
          isLoading: requestState.isLoading,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
