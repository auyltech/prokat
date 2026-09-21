import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/form_choice.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const CreateBookingScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  JobScheduleMode _scheduleMode = JobScheduleMode.none;

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
    });
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
      AppSnackBar.show(message: message, isSuccess: false, isError: true);

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
        .createBooking();

    AppSnackBar.show(
      message: result.message,
      isSuccess: result.success,
      isError: !result.success,
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

    final priceEntries = equipment?.prices;
    final ownerComment = equipment?.ownerComment?.trim() ?? '';

    final imageUrls = equipment?.displayImageUrls ?? const <String>[];

    final isPriceEntrySelected =
        bookingState.selectedPriceEntry != null &&
        equipment?.prices
                .where((item) => item.id == bookingState.selectedPriceEntry?.id)
                .firstOrNull !=
            null;

    final hasSchedule = _scheduleMode == JobScheduleMode.asap
        ? true
        : _scheduleMode == JobScheduleMode.scheduled &&
              bookingState.selectedDate != null &&
              bookingState.selectedTime != null;

    final canSubmit =
        bookingState.selectedEquipment != null &&
        isPriceEntrySelected &&
        bookingState.selectedLocation != null &&
        hasSchedule;

    final isSubmitting = ref
        .watch(bookingMutationProvider)
        .isActionActive("booking:create");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Favorite Button, equipment Name, model, owner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  equipment.name,
                                  style: theme.textTheme.titleLarge,
                                  maxLines:
                                      2, // Caps rendering at two lines max
                                  overflow: TextOverflow
                                      .ellipsis, // Clips extra text with "..."
                                ),

                                Text(
                                  equipment.model,
                                  style: theme.textTheme.titleMedium,
                                  maxLines:
                                      2, // Caps rendering at two lines max
                                  overflow: TextOverflow
                                      .ellipsis, // Clips extra text with "..."
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Favorite Button
                          GestureDetector(
                            onTap: isClient
                                ? () async {
                                    await ref
                                        .read(favoritesProvider.notifier)
                                        .toggleFavorite(equipment.id);
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      UserInfoTile(user: equipment.owner, showPresence: true),

                      const SizedBox(height: 12),

                      if (ownerComment.isNotEmpty) ...[
                        Text(
                          ownerComment,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      AddressPickerCard(
                        selectedAddress: selectedAddress,
                        onTap: () => SelectAddressSheet.show(
                          context,
                          service: "address",
                          from: "create_booking",
                          equipmentId: equipment.id,
                        ),
                        isRequired: true,
                        emptyHint: l10n.requestSelectDeliveryAddress,
                        requiredHintText: l10n.requestRequiredHint,
                      ),

                      const SizedBox(height: 20),

                      RequiredFieldLabel(
                        title: l10n.bookingSelectOfferedService,
                        showRequired: !isPriceEntrySelected,
                        requiredHint: l10n.requestRequiredHint,
                      ),

                      const SizedBox(height: 12),

                      ...?priceEntries?.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ServiceTariffBlock(
                            entry: entry,
                            selected:
                                bookingState.selectedPriceEntry?.id == entry.id,
                            onTap: () {
                              ref
                                  .read(bookingMutationProvider.notifier)
                                  .selectPriceEntry(entry);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      JobScheduleSection(
                        mode: _scheduleMode,
                        requiredHint: l10n.requestRequiredHint,
                        selectedDate: bookingState.selectedDate,
                        selectedTime: bookingState.selectedTime,
                        locale: locale,
                        onScheduled: _selectScheduled,
                        onAsap: _selectAsap,
                        onPickDate: _pickDate,
                        onPickTime: _pickTime,
                      ),

                      const SizedBox(height: 20),

                      JobCommentField(
                        hint: l10n.requestCommentHint,
                        onChanged: bookingNotifier.setComment,
                      ),

                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              label: l10n.placeOrder,
                              onPressed: (!canSubmit || isSubmitting)
                                  ? null
                                  : onSubmit,
                              isLoading: isSubmitting,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
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

class _ServiceTariffBlock extends StatelessWidget {
  const _ServiceTariffBlock({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final PriceEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;
    final priceText =
        '${formatPrice(entry.price)} ${getPriceRate(entry.priceRate, l10n: l10n)}';
    final serviceName = savedTariffTitle(entry, l10n);
    final label = serviceName == null ? priceText : '$priceText — $serviceName';

    return Material(
      color: selected ? primary : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? primary
              : theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
