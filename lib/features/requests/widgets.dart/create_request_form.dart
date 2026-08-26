import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_picker_component.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/core/widgets/time_picker_component.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/categories/widgets/user_category_selector.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSelectedAddress();
      _syncSelectedCategory();
    });
  }

  void _syncSelectedAddress() {
    final address = ref.read(locationProvider).selectedAddress;
    if (address?.id != null) {
      ref.read(requestMutationProvider.notifier).selectLocation(address!);
    }
  }

  void _syncSelectedCategory() {
    final profileCategoryId = ref
        .read(clientProfileProvider)
        .userProfile
        ?.selectedCategoryId;
    final categories =
        ref.read(categoriesProvider).valueOrNull?.items ?? const [];
    final foundCategory = categories
        .where((item) => item.id == profileCategoryId)
        .firstOrNull;

    if (profileCategoryId != null && foundCategory != null) {
      ref.read(requestMutationProvider.notifier).selectCategory(foundCategory);
    }
  }

  @override
  void dispose() {
    capacityController.dispose();
    rateController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    final requestState = ref.watch(requestMutationProvider);
    final selectedCategoryId = requestState.selectedCategory?.id;

    String message = "";

    if (selectedCategoryId == null) {
      message = l10n.pleaseSelectCategory;
    } else if (requestState.selectedLocation == null) {
      message = l10n.pleaseSelectLocation;
    } else if (requestState.selectedDate == null) {
      message = l10n.pleaseSelectDate;
    } else if (requestState.selectedTime == null) {
      message = l10n.pleaseSelectTime;
    }

    if (message.isNotEmpty) {
      AppSnackBar.show(message: message, isSuccess: false, isError: true);
      return;
    }

    final result = await ref
        .read(requestMutationProvider.notifier)
        .createRequest(
          categoryId: selectedCategoryId ?? "",
          capacity: capacityController.text.trim(),
          offeredRate: parseNullableInt(rateController.text.trim()) ?? 0,
          comment: commentController.text.trim(),
        );

    AppSnackBar.show(
      message: result.success ? l10n.requestCreated : result.message,
      isSuccess: result.success,
      isError: !result.success,
    );

    if (result.success && mounted) {
      context.push(AppRoutes.clientRequests);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(locationProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull?.items ?? const [];

    final requestState = ref.watch(requestMutationProvider);
    final requestNotifier = ref.read(requestMutationProvider.notifier);

    ref.listen(locationProvider, (previous, next) {
      final address = next.selectedAddress;

      if (address?.id != null) {
        ref.read(requestMutationProvider.notifier).selectLocation(address!);
      }
    });

    ref.listen(clientProfileProvider, (previous, next) {
      final profileCategoryId = next.userProfile?.selectedCategoryId;

      final foundCategory = categories
          .where((item) => item.id == profileCategoryId)
          .firstOrNull;

      if (profileCategoryId != null && foundCategory != null) {
        ref
            .read(requestMutationProvider.notifier)
            .selectCategory(foundCategory);
      }
    });

    final hasOfferedRate = rateController.text.isNotEmpty;

    final selectedCategoryId = requestState.selectedCategory?.id;
    final hasCategory = selectedCategoryId != null;

    final canSubmit =
        hasCategory &&
        requestState.selectedLocation != null &&
        hasOfferedRate &&
        requestState.selectedDate != null &&
        requestState.selectedTime != null;

    final action = requestState.activeActions
        .where((item) => item.id == "request:create")
        .firstOrNull;

    final isSubmitting = action == null
        ? false
        : action.status == MutationStatus.submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: l10n.services,
          trailing: hasCategory ? null : l10n.requiredHint,
        ),

        SizedBox(height: 8),

        UserCategorySelector(
          mode: "create_request",
          selectedCategoryId: selectedCategoryId,
        ),

        const SizedBox(height: 24),

        AddressPickerCard(
          selectedAddress: locationState.selectedAddress,
          onTap: () => SelectAddressSheet.show(
            context,
            service: "address",
            from: "create_request",
          ),
          isRequired: requestState.selectedLocation == null,
        ),

        const SizedBox(height: 12),

        ValueListenableBuilder<TextEditingValue>(
          valueListenable: capacityController,
          builder: (context, value, child) {
            final hasOfferedRate = value.text.isNotEmpty;
            return InputField(
              label: l10n.requiredCapacity,
              controller: capacityController,
              hint: l10n.capacityHint,
              icon: Icons.propane_outlined,
              suffixText: l10n.unitCubicMeters,
              isRequired: !hasOfferedRate,
              iconBgColor: Colors.black12,
            );
          },
        ),

        const SizedBox(height: 12),

        ValueListenableBuilder<TextEditingValue>(
          valueListenable: rateController,
          builder: (context, value, child) {
            final hasOfferedRate = value.text.isNotEmpty;
            return InputField(
              label: l10n.offeredRate,
              controller: rateController,
              hint: l10n.offeredRateHint,
              icon: Icons.payments_outlined,
              isRequired: !hasOfferedRate,
              iconBgColor: Colors.black12,
            );
          },
        ),

        const SizedBox(height: 12),

        InputField(
          label: l10n.comments,
          controller: commentController,
          hint: l10n.additionalDetails,
          icon: Icons.chat_bubble_outline_rounded,
          iconBgColor: Colors.black12,
        ),

        const SizedBox(height: 12),

        SectionTitle(
          title: l10n.selectDate,
          trailing: requestState.selectedDate == null
              ? l10n.requiredHint
              : null,
        ),

        DatePickerComponent(
          daysRange: 7, // Pass your dynamic 'x' range here
          isRequired: true, // Shows indicator text
          selectedDate: requestState.selectedDate,
          onDateSelected: (date) {
            requestNotifier.setDate(date);
          },
        ),

        const SizedBox(height: 12),

        SectionTitle(
          title: l10n.selectTime,
          trailing: requestState.selectedTime == null
              ? l10n.requiredHint
              : null,
        ),

        TimePickerComponent(
          slotLengthMinutes: 30, // 30 minute blocks
          startHour: 9, // Start at 09:00
          endHour: 17, // End at 17:00
          isRequired: true,
          selectedDateTime: requestState.selectedTime,
          onTimeSelected: (updatedDateTime) {
            requestNotifier.setTime(
              updatedDateTime,
            ); // This emits a full DateTime object
          },
        ),

        const SizedBox(height: 40),

        PrimaryButton(
          label: l10n.create,
          onPressed: (!canSubmit || isSubmitting) ? null : onSubmit,
          isLoading: isSubmitting,
        ),
      ],
    );
  }
}
