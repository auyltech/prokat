import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/features/bookings/widgets/booking_order_fields.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/booking_create_error_message.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/equipment_share/widgets/share_equipment_button.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String equipmentId;
  final String? companyId;
  final Widget? beforeOrderFields;

  const CreateBookingScreen({super.key, required this.equipmentId, this.companyId, this.beforeOrderFields});

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  JobScheduleMode _scheduleMode = JobScheduleMode.none;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final address = await ref
          .read(locationProvider.notifier)
          .ensureSelectedClientAddress(
            preferredId: ref
                .read(clientProfileProvider)
                .userProfile
                ?.selectedAddressId,
          );
      if (!mounted) return;
      if (address != null) {
        ref.read(bookingMutationProvider.notifier).selectLocation(address);
      }
      _selectOnlyTariff();
    });
  }

  void _selectOnlyTariff() {
    final equipment = ref.read(bookingMutationProvider).selectedEquipment;
    if (equipment == null) return;
    final prices = bookablePrices(equipment);
    if (prices.length != 1) return;
    final only = prices.first;
    final current = ref.read(bookingMutationProvider).selectedPriceEntry;
    if (current?.id == only.id) return;
    ref.read(bookingMutationProvider.notifier).selectPriceEntry(only);
  }

  Future<LocationModel?> _openAddressSheet(String equipmentId) async {
    final before = ref.read(locationProvider).selectedAddress;
    await SelectAddressSheet.show(
      context,
      service: 'address',
      from: 'create_booking',
      equipmentId: equipmentId,
    );
    if (!mounted) return null;
    final next = ref.read(locationProvider).selectedAddress;
    if (next == null) return null;
    if (next.id == before?.id && next.street == before?.street) return null;
    return next;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _selectAsap() {
    final when = jobScheduleAsapWhen();
    setState(() => _scheduleMode = JobScheduleMode.asap);
    ref
        .read(bookingMutationProvider.notifier)
        .setDateAndTime(
          date: DateTime(when.year, when.month, when.day),
          time: when,
        );
  }

  void _selectScheduled() {
    final today = jobScheduleToday();
    final bookingState = ref.read(bookingMutationProvider);
    final date = bookingState.selectedDate ?? today;
    final time = jobScheduleResolveTimeOn(
      date,
      bookingState.selectedTime ?? jobScheduleDefaultTimeOn(date),
    );
    setState(() => _scheduleMode = JobScheduleMode.scheduled);
    ref
        .read(bookingMutationProvider.notifier)
        .setDateAndTime(date: date, time: time);
  }

  Future<void> _pickDate() async {
    final current = ref.read(bookingMutationProvider).selectedDate;
    final picked = await showJobDatePicker(context: context, current: current);
    if (!mounted || picked == null) return;

    final day = DateTime(picked.year, picked.month, picked.day);
    final existing = ref.read(bookingMutationProvider).selectedTime;
    final time = jobScheduleResolveTimeOn(
      day,
      existing ?? jobScheduleDefaultTimeOn(day),
    );
    ref
        .read(bookingMutationProvider.notifier)
        .setDateAndTime(date: day, time: time);
  }

  Future<void> _pickTime() async {
    final bookingState = ref.read(bookingMutationProvider);
    final date = bookingState.selectedDate ?? jobScheduleToday();
    final picked = await showJobTimePicker(
      context: context,
      date: date,
      current: bookingState.selectedTime,
    );
    if (!mounted || picked == null) return;

    ref
        .read(bookingMutationProvider.notifier)
        .setDateAndTime(
          date: date,
          time: jobScheduleResolveTimeOn(date, picked),
        );
  }

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    _selectOnlyTariff();
    final bookingState = ref.read(bookingMutationProvider);
    String message = "";

    if (bookingState.selectedEquipment == null) {
      message = l10n.pleaseSelectEquipment;
    } else if (bookingState.selectedPriceEntry == null) {
      message = l10n.pleaseSelectPrice;
    } else if (bookingState.selectedLocation == null) {
      message = l10n.pleaseSelectLocation;
    } else if (_scheduleMode == JobScheduleMode.none) {
      message = l10n.pleaseSelectDate;
    } else if (_scheduleMode == JobScheduleMode.scheduled &&
        (bookingState.selectedDate == null ||
            bookingState.selectedTime == null)) {
      message = l10n.pleaseSelectTime;
    } else if (_scheduleMode == JobScheduleMode.scheduled) {
      final merged = DateTime(
        bookingState.selectedDate!.year,
        bookingState.selectedDate!.month,
        bookingState.selectedDate!.day,
        bookingState.selectedTime!.hour,
        bookingState.selectedTime!.minute,
      );
      if (merged.isBefore(DateTime.now())) {
        message = l10n.pleaseSelectTime;
      }
    }

    if (message.isNotEmpty) {
      AppToast.show(message: message, type: AppToastType.error);

      return;
    }

    if (_scheduleMode == JobScheduleMode.asap) {
      final when = jobScheduleAsapWhen();
      ref
          .read(bookingMutationProvider.notifier)
          .setDateAndTime(
            date: DateTime(when.year, when.month, when.day),
            time: when,
          );
    }

    final result = await ref
        .read(bookingMutationProvider.notifier)
        .createBooking(companyId: widget.companyId);

    AppToast.show(
      message: result.success
          ? l10n.orderCreated
          : bookingCreateErrorMessage(
              l10n: l10n,
              errorCode: result.errorCode,
              fallback: result.message,
            ),
      type: result.success ? AppToastType.success : AppToastType.error,
    );

    if (result.success && mounted) {
      unawaited(context.push(AppRoutes.clientOrders));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authSession = ref.watch(authProvider).session;
    final isClient = authSession != null ? true : false;

    /// AUTO SYNC address → booking
    ref.listen(locationProvider, (previous, next) {
      final address = next.selectedAddress;

      if (address != null && address.id != null) {
        ref.read(bookingMutationProvider.notifier).selectLocation(address);
      }
    });

    final bookingState = ref.watch(bookingMutationProvider);
    final bookingNotifier = ref.read(bookingMutationProvider.notifier);
    final locale = l10n.localeName;

    final locationState = ref.watch(locationProvider);
    final selectedAddress = locationState.selectedAddress;

    final equipment = bookingState.selectedEquipment;

    final bool isFavorite =
        ref.watch(
          favoritesProvider.select(
            (s) => s.favoritesIds?.contains(equipment?.id),
          ),
        ) ??
        false;

    final ownerComment = equipment?.ownerComment?.trim() ?? '';

    final imageUrls = equipment?.displayImageUrls ?? const <String>[];

    final prices = equipment == null
        ? const <PriceEntry>[]
        : bookablePrices(equipment);
    final selectedPrice = prices
        .where((entry) => entry.id == bookingState.selectedPriceEntry?.id)
        .firstOrNull;

    final hasSchedule = _scheduleMode == JobScheduleMode.asap
        ? true
        : _scheduleMode == JobScheduleMode.scheduled &&
              bookingState.selectedDate != null &&
              bookingState.selectedTime != null;

    final canSubmit =
        bookingState.selectedEquipment != null &&
        (selectedPrice != null || prices.length == 1) &&
        bookingState.selectedLocation != null &&
        hasSchedule;

    final isSubmitting = ref
        .watch(bookingMutationProvider)
        .isActionActive("booking:create");

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: ListView(
        children: [
          if (equipment == null)
            EmptyStateTile(
              imageName: 'empty_equipment.png',
              title: l10n.notFound,
              subtitle: l10n.equipmentNotFound,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 1. ASSET HEADER CARD
                EquipmentImageHeader(imageUrls: imageUrls),

                Padding(
                  padding: const EdgeInsets.all(AppDimens.s16$base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipment.name,
                                  style: AppFonts.headingM(context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  equipment.model,
                                  style: AppFonts.caption(context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimens.s08$sm),
                          if (widget.companyId == null) ShareEquipmentButton(equipment: equipment),
                          const SizedBox(width: AppDimens.s08$sm),
                          if (widget.companyId == null) AppIconButton(
                            icon: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            tone: AppIconButtonTone.destructive,
                            onTap: isClient
                                ? () async {
                                    await ref
                                        .read(favoritesProvider.notifier)
                                        .toggleFavorite(equipment.id);
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.s12$md),
                      UserInfoTile(user: equipment.owner, showPresence: true),
                      if (ownerComment.isNotEmpty) ...[
                        const SizedBox(height: AppDimens.s12$md),
                        Text(ownerComment, style: AppFonts.body14(context)),
                      ],
                      const SizedBox(height: AppDimens.s16$base),
                      if (widget.beforeOrderFields != null) widget.beforeOrderFields!,
                      BookingOrderFields(
                        isEquipmentGroup: bookingIsEquipmentGroup(equipment),
                        address:
                            selectedAddress ?? bookingState.selectedLocation,
                        openAddressSheet: () => _openAddressSheet(equipment.id),
                        onAddressChanged: (address) {
                          ref
                              .read(bookingMutationProvider.notifier)
                              .selectLocation(address);
                        },
                        prices: prices,
                        selectedPrice: selectedPrice,
                        onPriceChanged: (entry) {
                          ref
                              .read(bookingMutationProvider.notifier)
                              .selectPriceEntry(entry);
                        },
                        scheduleMode: _scheduleMode,
                        selectedDate: bookingState.selectedDate,
                        selectedTime: bookingState.selectedTime,
                        locale: locale,
                        onScheduled: _selectScheduled,
                        onAsap: _selectAsap,
                        onPickDate: _pickDate,
                        onPickTime: _pickTime,
                        commentController: _commentController,
                        onCommentChanged: bookingNotifier.setComment,
                        canSubmit: canSubmit,
                        submitting: isSubmitting,
                        onSubmit: () => unawaited(onSubmit()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
