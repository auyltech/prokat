import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/form_choice.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/vacuum_trucks.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _offeredRateMax = 100000;

enum _PriceMode { none, waitOwner, budget }

class CreateRequestForm extends ConsumerStatefulWidget {
  const CreateRequestForm({super.key});

  @override
  ConsumerState<CreateRequestForm> createState() => _CreateRequestFormState();
}

class _CreateRequestFormState extends ConsumerState<CreateRequestForm> {
  final rateController = TextEditingController();
  final commentController = TextEditingController();
  _PriceMode _priceMode = _PriceMode.none;
  JobScheduleMode _scheduleMode = JobScheduleMode.none;

  @override
  void initState() {
    super.initState();
    rateController.addListener(_onRateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSelectedAddress();
      _syncVacuumCategory();
    });
  }

  void _onRateChanged() {
    if (mounted) setState(() {});
  }

  void _syncSelectedAddress() {
    final address = ref.read(locationProvider).selectedAddress;
    if (address?.id != null) {
      ref.read(requestMutationProvider.notifier).selectLocation(address!);
    }
  }

  void _syncVacuumCategory() {
    final vacuum = vacuumTrucksCategory(ref.read(catalogProvider).valueOrNull);
    if (vacuum == null) return;
    ref.read(requestMutationProvider.notifier).selectCategory(vacuum);
  }

  void _selectWaitOwnerPrice() {
    setState(() => _priceMode = _PriceMode.waitOwner);
    rateController.clear();
  }

  void _selectBudget() {
    setState(() => _priceMode = _PriceMode.budget);
  }

  void _selectAsap() {
    final when = jobScheduleAsapWhen();
    setState(() => _scheduleMode = JobScheduleMode.asap);
    ref
        .read(requestMutationProvider.notifier)
        .setDateAndTime(
          date: DateTime(when.year, when.month, when.day),
          time: when,
        );
  }

  void _selectScheduled() {
    final today = jobScheduleToday();
    final requestState = ref.read(requestMutationProvider);
    final date = requestState.selectedDate ?? today;
    final time = jobScheduleResolveTimeOn(
      date,
      requestState.selectedTime ?? jobScheduleDefaultTimeOn(date),
    );
    setState(() => _scheduleMode = JobScheduleMode.scheduled);
    ref
        .read(requestMutationProvider.notifier)
        .setDateAndTime(date: date, time: time);
  }

  Future<void> _openCategorySheet() async {
    await CategorySelectionSheet.show(
      context,
      service: CategorySheetMode.createRequest,
    );
  }

  Future<void> _pickDate() async {
    final current = ref.read(requestMutationProvider).selectedDate;
    final picked = await showJobDatePicker(context: context, current: current);
    if (!mounted || picked == null) return;

    final day = DateTime(picked.year, picked.month, picked.day);
    final existing = ref.read(requestMutationProvider).selectedTime;
    final time = jobScheduleResolveTimeOn(
      day,
      existing ?? jobScheduleDefaultTimeOn(day),
    );
    ref
        .read(requestMutationProvider.notifier)
        .setDateAndTime(date: day, time: time);
  }

  Future<void> _pickTime() async {
    final requestState = ref.read(requestMutationProvider);
    final date = requestState.selectedDate ?? jobScheduleToday();
    final picked = await showJobTimePicker(
      context: context,
      date: date,
      current: requestState.selectedTime,
    );
    if (!mounted || picked == null) return;

    ref
        .read(requestMutationProvider.notifier)
        .setDateAndTime(
          date: date,
          time: jobScheduleResolveTimeOn(date, picked),
        );
  }

  @override
  void dispose() {
    rateController.removeListener(_onRateChanged);
    rateController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final requestState = ref.read(requestMutationProvider);
    final selectedCategoryId = requestState.selectedCategory?.id;
    final offeredRate = _priceMode == _PriceMode.waitOwner
        ? null
        : parseNullableInt(rateController.text.trim());

    String message = "";

    if (selectedCategoryId == null) {
      message = l10n.pleaseSelectCategory;
    } else if (requestState.selectedLocation == null) {
      message = l10n.pleaseSelectLocation;
    } else if (_priceMode == _PriceMode.none) {
      message = l10n.pleaseEnterValidPrice;
    } else if (_priceMode == _PriceMode.budget &&
        (offeredRate == null || offeredRate <= 0)) {
      message = l10n.pleaseEnterValidPrice;
    } else if (_priceMode == _PriceMode.budget &&
        offeredRate != null &&
        offeredRate > _offeredRateMax) {
      message = l10n.priceMaximumExceeded;
    } else if (_scheduleMode == JobScheduleMode.none) {
      message = l10n.pleaseSelectDate;
    } else if (_scheduleMode == JobScheduleMode.scheduled &&
        (requestState.selectedDate == null ||
            requestState.selectedTime == null)) {
      message = l10n.pleaseSelectTime;
    } else if (_scheduleMode == JobScheduleMode.scheduled) {
      final merged = DateTime(
        requestState.selectedDate!.year,
        requestState.selectedDate!.month,
        requestState.selectedDate!.day,
        requestState.selectedTime!.hour,
        requestState.selectedTime!.minute,
      );
      if (merged.isBefore(DateTime.now())) {
        message = l10n.pleaseSelectTime;
      }
    }

    if (message.isNotEmpty) {
      AppSnackBar.show(message: message, isSuccess: false, isError: true);
      return;
    }

    if (_scheduleMode == JobScheduleMode.asap) {
      final when = jobScheduleAsapWhen();
      ref
          .read(requestMutationProvider.notifier)
          .setDateAndTime(
            date: DateTime(when.year, when.month, when.day),
            time: when,
          );
    }

    final result = await ref
        .read(requestMutationProvider.notifier)
        .createRequest(
          categoryId: selectedCategoryId ?? "",
          offeredRate: offeredRate,
          comment: commentController.text.trim(),
          allowPastSchedule: _scheduleMode == JobScheduleMode.asap,
        );

    AppSnackBar.show(
      message: result.success ? l10n.requestCreated : result.message,
      isSuccess: result.success,
      isError: !result.success,
    );

    if (result.success && mounted) {
      unawaited(context.push(AppRoutes.clientRequests));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final locationState = ref.watch(locationProvider);
    final catalog = ref.watch(catalogProvider).valueOrNull;

    final requestState = ref.watch(requestMutationProvider);

    ref.listen(locationProvider, (previous, next) {
      final address = next.selectedAddress;
      if (address?.id != null) {
        ref.read(requestMutationProvider.notifier).selectLocation(address!);
      }
    });

    ref.listen(catalogProvider, (previous, next) {
      final nextVacuum = vacuumTrucksCategory(next.valueOrNull);
      if (nextVacuum == null) return;
      ref.read(requestMutationProvider.notifier).selectCategory(nextVacuum);
    });

    final vacuum = vacuumTrucksCategory(catalog);
    if (vacuum != null && requestState.selectedCategory?.id != vacuum.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncVacuumCategory();
      });
    }

    final hasBudget =
        _priceMode == _PriceMode.waitOwner ||
        (_priceMode == _PriceMode.budget &&
            (parseNullableInt(rateController.text.trim()) ?? 0) > 0);

    final hasSchedule = _scheduleMode == JobScheduleMode.asap
        ? true
        : _scheduleMode == JobScheduleMode.scheduled &&
              requestState.selectedDate != null &&
              requestState.selectedTime != null;

    final canSubmit =
        requestState.selectedCategory != null &&
        requestState.selectedLocation != null &&
        hasBudget &&
        hasSchedule;

    final action = requestState.activeActions
        .where((item) => item.id == "request:create")
        .firstOrNull;

    final isSubmitting = action == null
        ? false
        : action.status == MutationStatus.submitting;

    final categoryName =
        vacuum?.localizedName(locale) ??
        requestState.selectedCategory?.localizedName(locale) ??
        'Вакуумные машины';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryPickerCard(
          title: l10n.requestCategoryTitle,
          categoryName: categoryName,
          onTap: _openCategorySheet,
        ),

        AddressPickerCard(
          selectedAddress: locationState.selectedAddress,
          onTap: () => SelectAddressSheet.show(
            context,
            service: "address",
            from: "create_request",
          ),
          isRequired: true,
          emptyHint: l10n.requestSelectDeliveryAddress,
          requiredHintText: l10n.requestRequiredHint,
        ),

        const SizedBox(height: 20),

        RequiredFieldLabel(
          title: l10n.price,
          showRequired: _priceMode == _PriceMode.none,
          requiredHint: l10n.requestRequiredHint,
        ),
        const SizedBox(height: 10),
        ChoicePair(
          leftLabel: l10n.requestWaitOwnerPrice,
          rightLabel: l10n.requestSetBudget,
          leftSelected: _priceMode == _PriceMode.waitOwner,
          rightSelected: _priceMode == _PriceMode.budget,
          onLeft: _selectWaitOwnerPrice,
          onRight: _selectBudget,
        ),

        if (_priceMode == _PriceMode.budget) ...[
          const SizedBox(height: 14),
          _BudgetAmountField(
            label: l10n.requestMyBudget,
            requiredHint: l10n.requestRequiredHint,
            hint: l10n.offeredRateHint,
            controller: rateController,
          ),
        ],

        const SizedBox(height: 20),

        JobScheduleSection(
          mode: _scheduleMode,
          requiredHint: l10n.requestRequiredHint,
          selectedDate: requestState.selectedDate,
          selectedTime: requestState.selectedTime,
          locale: locale,
          onScheduled: _selectScheduled,
          onAsap: _selectAsap,
          onPickDate: _pickDate,
          onPickTime: _pickTime,
        ),

        const SizedBox(height: 20),

        JobCommentField(
          hint: l10n.requestCommentHint,
          controller: commentController,
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

class _CategoryPickerCard extends StatelessWidget {
  const _CategoryPickerCard({
    required this.title,
    required this.categoryName,
    required this.onTap,
  });

  final String title;
  final String categoryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.truck,
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAmountField extends StatelessWidget {
  const _BudgetAmountField({
    required this.label,
    required this.requiredHint,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String requiredHint;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBlank = controller.text.trim().isEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: [
              if (isBlank)
                TextSpan(
                  text: ' $requiredHint',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            const MaxIntInputFormatter(_offeredRateMax),
          ],
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w400,
            ),
            suffixText: '₸',
            suffixStyle: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            isDense: true,
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
