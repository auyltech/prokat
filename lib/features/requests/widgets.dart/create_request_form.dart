import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/form_choice.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/categories/widgets/category_picker_sheet.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/requests/request_create_error_message.dart';
import 'package:prokat/features/requests/state/request_comment_requirement.dart';
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
  late final FocusNode _rateFocus;
  _PriceMode _priceMode = _PriceMode.none;
  JobScheduleMode _scheduleMode = JobScheduleMode.none;

  @override
  void initState() {
    super.initState();
    _rateFocus = FocusNode();
    rateController.addListener(_onRateChanged);
    commentController.addListener(_onRateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSelectedAddress();
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

  Future<Category?> _openCategorySheet() async {
    final catalog = ref.read(catalogProvider).valueOrNull;
    final groupTabs = userVisibleCatalogGroups(catalog);
    final group = coerceCatalogGroup(
      ref.read(mutationCatalogGroupProvider),
      groupTabs,
    );
    final categories =
        (ref.read(categoriesProvider).valueOrNull?.items ?? const [])
            .where((item) => item.catalogGroup == group)
            .toList();
    final selectedId = ref.read(requestMutationProvider).selectedCategory?.id;

    final picked = await CategoryPickerSheet.show(
      context,
      categories: categories,
      group: group,
      selectedId: selectedId,
      includeAllOption: false,
    );
    if (!mounted || picked == null || picked.isAll) return null;
    return picked.category;
  }

  Future<LocationModel?> _openAddressSheet() async {
    final beforeId = ref.read(locationProvider).selectedAddress?.id;
    await SelectAddressSheet.show(
      context,
      service: 'address',
      from: 'create_request',
    );
    if (!mounted) return null;
    final after = ref.read(locationProvider).selectedAddress;
    if (after == null || after.id == beforeId) return null;
    return after;
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
    commentController.removeListener(_onRateChanged);
    rateController.dispose();
    commentController.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final requestState = ref.read(requestMutationProvider);
    final selectedCategory = requestState.selectedCategory;
    final selectedCategoryId = selectedCategory?.id;
    final commentRequired =
        selectedCategory != null &&
        requestCategoryRequiresComment(selectedCategory);
    final offeredRate = _priceMode == _PriceMode.waitOwner
        ? null
        : parseNullableInt(rateController.text.trim());

    String message = '';

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

    if (message.isEmpty &&
        commentRequired &&
        commentController.text.trim().isEmpty) {
      message = _commentHint(l10n, selectedCategory);
    }

    if (message.isNotEmpty) {
      AppToast.show(message: message, type: AppToastType.error);
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
          categoryId: selectedCategoryId ?? '',
          offeredRate: offeredRate,
          comment: commentController.text.trim(),
          allowPastSchedule: _scheduleMode == JobScheduleMode.asap,
        );

    AppToast.show(
      message: result.success
          ? l10n.requestCreated
          : requestCreateErrorMessage(
              l10n: l10n,
              errorCode: result.errorCode,
              fallback: result.message,
            ),
      type: result.success ? AppToastType.success : AppToastType.error,
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
    final groupTabs = userVisibleCatalogGroups(catalog);
    final mutationGroup = coerceCatalogGroup(
      ref.watch(mutationCatalogGroupProvider),
      groupTabs,
    );

    final requestState = ref.watch(requestMutationProvider);
    final selectedCategory = requestState.selectedCategory;
    final selectedAddress =
        requestState.selectedLocation ?? locationState.selectedAddress;

    ref.listen(locationProvider, (previous, next) {
      final address = next.selectedAddress;
      if (address?.id != null) {
        ref.read(requestMutationProvider.notifier).selectLocation(address!);
      }
    });

    final hasBudget =
        _priceMode == _PriceMode.waitOwner ||
        (_priceMode == _PriceMode.budget &&
            (parseNullableInt(rateController.text.trim()) ?? 0) > 0);

    final hasSchedule = _scheduleMode == JobScheduleMode.asap
        ? true
        : _scheduleMode == JobScheduleMode.scheduled &&
              requestState.selectedDate != null &&
              requestState.selectedTime != null;

    final commentRequired =
        selectedCategory != null &&
        requestCategoryRequiresComment(selectedCategory);
    final hasComment =
        !commentRequired || commentController.text.trim().isNotEmpty;

    final canSubmit =
        selectedCategory != null &&
        requestState.selectedLocation != null &&
        hasBudget &&
        hasSchedule &&
        hasComment;

    final action = requestState.activeActions
        .where((item) => item.id == 'request:create')
        .firstOrNull;

    final isSubmitting = action == null
        ? false
        : action.status == MutationStatus.submitting;

    final addressLabel = selectedAddress == null
        ? ''
        : formatLocationModel(ref, context, selectedAddress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CatalogGroupTabs(
          groups: groupTabs,
          selected: mutationGroup,
          onChanged: (group) {
            ref.read(mutationCatalogGroupProvider.notifier).select(group);
            ref.read(requestMutationProvider.notifier).clearCategory();
          },
        ),
        if (groupTabs.length > 1) const SizedBox(height: AppDimens.s12$md),
        AppDropdownField<Category>(
          title: l10n.requestCategoryTitle,
          hint: l10n.pleaseSelectCategory,
          isRequired: true,
          sheetTitle: l10n.selectCategory,
          value: selectedCategory,
          selectedLabel: selectedCategory?.localizedName(locale),
          openCustomSheet: _openCategorySheet,
          onChanged: (category) {
            ref.read(requestMutationProvider.notifier).selectCategory(category);
          },
        ),
        const SizedBox(height: AppDimens.s16$base),
        AppDropdownField<LocationModel>(
          title: l10n.deliveryLocation,
          hint: l10n.requestSelectDeliveryAddress,
          isRequired: true,
          sheetTitle: l10n.selectAddress,
          value: selectedAddress,
          selectedLabel: addressLabel,
          openCustomSheet: _openAddressSheet,
          onChanged: (address) {
            ref.read(requestMutationProvider.notifier).selectLocation(address);
          },
        ),
        const SizedBox(height: AppDimens.s20$lg),
        RequiredFieldLabel(
          title: l10n.price,
          showRequired: _priceMode == _PriceMode.none,
        ),
        const SizedBox(height: AppDimens.inputLabelGap),
        ChoicePair(
          leftLabel: l10n.requestWaitOwnerPrice,
          rightLabel: l10n.requestSetBudget,
          leftSelected: _priceMode == _PriceMode.waitOwner,
          rightSelected: _priceMode == _PriceMode.budget,
          onLeft: _selectWaitOwnerPrice,
          onRight: _selectBudget,
        ),
        AppReveal(
          visible: _priceMode == _PriceMode.budget,
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimens.s16$base),
            child: TapRegion(
              onTapOutside: (_) {
                _rateFocus.unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: AppTextField(
                controller: rateController,
                focusNode: _rateFocus,
                title: l10n.requestMyBudget,
                isRequired: true,
                hint: l10n.offeredRateHint,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  const MaxIntInputFormatter(_offeredRateMax),
                ],
                prefix: Text(
                  '₸',
                  style: AppFonts.body16SemiBold(context)
                      .copyWith(color: context.colors.text.secondary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.s20$lg),
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
        const SizedBox(height: AppDimens.s20$lg),
        AppTextArea(
          title: l10n.requestCommentTitle,
          hint: _commentHint(l10n, selectedCategory),
          isRequired: commentRequired,
          controller: commentController,
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: AppDimens.s32$xxl),
        AppElevatedButton(
          title: l10n.create,
          onTap: (!canSubmit || isSubmitting) ? null : onSubmit,
          isLoading: isSubmitting,
        ),
      ],
    );
  }
}

String _commentHint(AppLocalizations l10n, Category? category) {
  if (category == null || !requestCategoryRequiresComment(category)) {
    return l10n.requestCommentHint;
  }
  return category.catalogGroup == CatalogGroup.equipment
      ? l10n.requestCommentOtherEquipmentHint
      : l10n.requestCommentOtherMachineryHint;
}
