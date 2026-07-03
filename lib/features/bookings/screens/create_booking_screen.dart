import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_picker_component.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/core/widgets/time_picker_component.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:go_router/go_router.dart';
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
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(equipmentProvider.notifier).getClientEquipment();

      ref.read(locationProvider.notifier).getClientLocations();
    });
  }

  Future<void> onSubmit() async {
    final bookingState = ref.read(bookingProvider);
    String message = "";

    if (bookingState.selectedEquipment == null) {
      message = "Please select equipment";
    } else if (bookingState.selectedPriceEntry == null) {
      message = "Please select price";
    } else if (bookingState.selectedLocation == null) {
      message = "Please select location";
    } else if (bookingState.selectedDate == null) {
      message = "Please select date";
    } else if (bookingState.selectedTime == null) {
      message = "Please select time";
    }

    if (message.isNotEmpty) {
      AppSnackBar.show(message: message, isSuccess: false, isError: true);

      return;
    }

    final result = await ref.read(bookingProvider.notifier).createBooking();

    AppSnackBar.show(
      message: result.message,
      isSuccess: result.success,
      isError: !result.success,
    );

    if (result.success && mounted) {
      context.push(AppRoutes.clientOrders);
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
        ref.read(bookingProvider.notifier).selectLocation(address);
      }
    });

    final bookingState = ref.watch(bookingProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);

    final locationState = ref.watch(locationProvider);
    final selectedAddress = locationState.selectedAddress;

    final equipment = bookingState.selectedEquipment;

    final notifier = ref.read(favoritesProvider.notifier);
    final bool isFavorite = notifier.isFavorite(equipment?.id ?? '');

    final priceEntries = equipment?.prices;

    final displayUrl = equipment?.imageUrl ?? "";

    final isPriceEntrySelected =
        bookingState.selectedPriceEntry != null &&
        equipment?.prices
                .where((item) => item.id == bookingState.selectedPriceEntry?.id)
                .firstOrNull !=
            null;

    final canSubmit =
        bookingState.selectedEquipment != null &&
        isPriceEntrySelected &&
        bookingState.selectedLocation != null &&
        bookingState.selectedDate != null &&
        bookingState.selectedTime != null;

    final action = bookingState.activeActions
        .where((item) => item.id == "booking:create")
        .firstOrNull;

    final isSubmitting = action == null
        ? false
        : action.status == MutationStatus.submitting;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        children: [
          if (equipment == null)
            EmptyStateTile(
              icon: Icons.error,
              title: "Not Found",
              subtitle: l10n.equipmentNotFound,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 1. ASSET HEADER CARD
                EquipmentImageHeader(imageUrl: displayUrl),

                Padding(
                  padding: EdgeInsets.all(16),
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
                                    ref
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

                      UserInfoTile(user: equipment.owner),

                      const SizedBox(height: 12),

                      /// Pricing
                      SectionTitle(
                        title: l10n.servicePlan,
                        trailing: isPriceEntrySelected ? null : "* Required",
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(priceEntries?.length ?? 0, (
                          index,
                        ) {
                          final entry = priceEntries?[index];
                          final isSelected =
                              bookingState.selectedPriceEntry?.id == entry?.id;

                          return GestureDetector(
                            onTap: () {
                              if (entry != null) {
                                ref
                                    .read(bookingProvider.notifier)
                                    .selectPriceEntry(entry);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceBright,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                              ),
                              child: Text(
                                "${formatPrice(entry?.price)} ${getPriceRate(entry?.priceRate)}",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      /// Address & Schedule
                      SectionTitle(
                        title: l10n.address,
                        trailing: bookingState.selectedLocation == null
                            ? "* Required"
                            : null,
                      ),

                      const SizedBox(height: 12),

                      AddressPickerCard(
                        selectedAddress: selectedAddress,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          backgroundColor:
                              Colors.transparent, // For rounded corners
                          isScrollControlled: true,
                          builder: (context) => SelectAddressSheet(
                            equipmentId: equipment.id,
                            service: "equipment",
                            from: "create_booking",
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SectionTitle(
                        title: "Select Date",
                        trailing: bookingState.selectedDate == null
                            ? "* Required"
                            : null,
                      ),

                      DatePickerComponent(
                        daysRange: 7, // Pass your dynamic 'x' range here
                        isRequired: true, // Shows indicator text
                        selectedDate: bookingState.selectedDate,
                        onDateSelected: (date) {
                          bookingNotifier.setDate(date);
                        },
                      ),

                      SectionTitle(
                        title: "Select Time",
                        trailing: bookingState.selectedTime == null
                            ? "* Required"
                            : null,
                      ),

                      const SizedBox(height: 12),

                      TimePickerComponent(
                        slotLengthMinutes: 30, // 30 minute blocks
                        startHour: 9, // Start at 09:00
                        endHour: 17, // End at 17:00
                        isRequired: true,
                        selectedDateTime: bookingState.selectedTime,
                        onTimeSelected: (updatedDateTime) {
                          bookingNotifier.setTime(
                            updatedDateTime,
                          ); // This emits a full DateTime object
                        },
                      ),

                      const SizedBox(height: 12),

                      /// 4. ADDITIONAL NOTES
                      SectionTitle(title: l10n.noteToOperator),

                      const SizedBox(height: 12),

                      TextField(
                        maxLines: 3,
                        style: theme.textTheme.bodyMedium,
                        onChanged: (v) => bookingNotifier.setComment(v),
                        decoration: InputDecoration(
                          hintText: l10n.siteAccessHint,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.cardColor,

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),

                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              label: "Place Order",
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
