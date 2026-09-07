import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/media/media_providers.dart';
import 'package:prokat/core/media/resolve_media_url.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_picker_component.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/core/widgets/time_picker_component.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _offeredRateMax = 100000;

class CreateRequestForm extends ConsumerStatefulWidget {
  const CreateRequestForm({super.key});

  @override
  ConsumerState<CreateRequestForm> createState() => _CreateRequestFormState();
}

class _CreateRequestFormState extends ConsumerState<CreateRequestForm> {
  final rateController = TextEditingController();
  final commentController = TextEditingController();

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
    final vacuum = _vacuumCategory(ref.read(catalogProvider).valueOrNull);
    if (vacuum == null) return;
    ref.read(requestMutationProvider.notifier).selectCategory(vacuum);
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
    final offeredRate = parseNullableInt(rateController.text.trim());

    String message = "";

    if (selectedCategoryId == null) {
      message = l10n.pleaseSelectCategory;
    } else if (requestState.selectedLocation == null) {
      message = l10n.pleaseSelectLocation;
    } else if (offeredRate == null || offeredRate <= 0) {
      message = l10n.pleaseEnterValidPrice;
    } else if (offeredRate > _offeredRateMax) {
      message = l10n.priceMaximumExceeded;
    } else if (requestState.selectedDate == null) {
      message = l10n.pleaseSelectDate;
    } else if (requestState.selectedTime == null) {
      message = l10n.pleaseSelectTime;
    } else {
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

    final result = await ref
        .read(requestMutationProvider.notifier)
        .createRequest(
          categoryId: selectedCategoryId ?? "",
          offeredRate: offeredRate!,
          comment: commentController.text.trim(),
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

    final locationState = ref.watch(locationProvider);
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final vacuum = _vacuumCategory(catalog);

    final requestState = ref.watch(requestMutationProvider);
    final requestNotifier = ref.read(requestMutationProvider.notifier);

    ref.listen(locationProvider, (previous, next) {
      final address = next.selectedAddress;

      if (address?.id != null) {
        ref.read(requestMutationProvider.notifier).selectLocation(address!);
      }
    });

    ref.listen(catalogProvider, (previous, next) {
      final nextVacuum = _vacuumCategory(next.valueOrNull);
      if (nextVacuum == null) return;
      ref.read(requestMutationProvider.notifier).selectCategory(nextVacuum);
    });

    final hasOfferedRate = rateController.text.isNotEmpty;
    final selectedCategoryId = requestState.selectedCategory?.id;
    final hasCategory = selectedCategoryId != null;

    final hasValidSchedule = () {
      final date = requestState.selectedDate;
      final time = requestState.selectedTime;
      if (date == null || time == null) return false;
      final merged = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      return !merged.isBefore(DateTime.now());
    }();

    final canSubmit =
        hasCategory &&
        requestState.selectedLocation != null &&
        hasOfferedRate &&
        hasValidSchedule;

    final action = requestState.activeActions
        .where((item) => item.id == "request:create")
        .firstOrNull;

    final isSubmitting = action == null
        ? false
        : action.status == MutationStatus.submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.services),

        const SizedBox(height: 8),

        _LockedVacuumServiceRow(category: vacuum),

        const SizedBox(height: 24),

        AddressPickerCard(
          selectedAddress: locationState.selectedAddress,
          onTap: () => SelectAddressSheet.show(
            context,
            service: "address",
            from: "create_request",
          ),
          isRequired: true,
        ),

        const SizedBox(height: 12),

        InputField(
          label: l10n.offeredRate,
          controller: rateController,
          hint: l10n.offeredRateHint,
          icon: Icons.payments_outlined,
          isRequired: true,
          isNumeric: true,
          iconBgColor: Colors.black12,
          requiredHintText: l10n.requiredHint,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            const MaxIntInputFormatter(_offeredRateMax),
          ],
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
          daysRange: 7,
          isRequired: true,
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

        const SizedBox(height: 12),

        TimePickerComponent(
          slotLengthMinutes: 30,
          startHour: 9,
          endHour: 17,
          isRequired: true,
          referenceDate: requestState.selectedDate,
          selectedDateTime: requestState.selectedTime,
          onTimeSelected: (updatedDateTime) {
            requestNotifier.setTime(updatedDateTime);
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

Category? _vacuumCategory(CatalogBundle? catalog) {
  final item = catalog?.categories
      .where((category) => category.slug == 'vacuum_trucks')
      .firstOrNull;
  if (item == null) return null;
  return Category.fromCatalog(item);
}

class _LockedVacuumServiceRow extends StatelessWidget {
  const _LockedVacuumServiceRow({required this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = category?.localizedName(
      Localizations.localeOf(context).languageCode,
    );

    return Row(
      children: [
        Container(
          width: 45,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: _VacuumCategoryIcon(imageUrl: category?.imageUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name == null || name.isEmpty ? '—' : name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _VacuumCategoryIcon extends ConsumerWidget {
  const _VacuumCategoryIcon({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = resolveMediaUrl(imageUrl);

    if (resolved == null || resolved.isEmpty) {
      return const _VacuumFallbackIcon();
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      cacheManager: isApiMediaUrl(resolved)
          ? ref.watch(mediaCacheManagerProvider)
          : null,
      fit: BoxFit.contain,
      placeholder: (_, _) => const _VacuumFallbackIcon(),
      errorWidget: (_, _, _) => const _VacuumFallbackIcon(),
    );
  }
}

class _VacuumFallbackIcon extends StatelessWidget {
  const _VacuumFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      LucideIcons.truck,
      color: Theme.of(context).colorScheme.onSurface,
      size: 24,
    );
  }
}
