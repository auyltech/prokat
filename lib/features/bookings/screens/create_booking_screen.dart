import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_time_button.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/utils/date_time.dart';

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
      ref.read(equipmentProvider.notifier).getRenterEquipment();
      ref.read(locationProvider.notifier).getRenterLocations();
    });
  }

  int selectedPriceIndex = 0;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> _onPressed() async {
    final result = await ref.read(bookingProvider.notifier).createBooking();

    if (mounted) {
      AppSnackBar.show(
        context,
        message: result ? "Order created" : "Failed to create order",
        isSuccess: result,
        isError: !result,
      );

      if (result) context.push(AppRoutes.clientOrders);
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

    final notifier = ref.read(favoriteProvider.notifier);
    final bool isFavorite = notifier.isFavorite(equipment?.id ?? '');

    final priceEntries = equipment?.prices;

    final displayUrl = equipment?.imageUrl ?? "";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        children: [
          if (authSession == null)
            _buildCenteredFallback(
              icon: Icons.login_outlined,
              message: l10n.loginToBook,
            )
          else if (equipment == null)
            _buildCenteredFallback(
              icon: Icons.login_outlined,
              message: l10n.equipmentNotFound,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 1. ASSET HEADER CARD
                EquipmentImageHeader(imageUrl: displayUrl),

                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Favorite Button
                          GestureDetector(
                            onTap: isClient
                                ? () async {
                                    ref
                                        .read(favoriteProvider.notifier)
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

                          const SizedBox(width: 8),

                          // Favorite Button, equipment Name, model, owner
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${equipment.name} ${equipment.model}"
                                      .toUpperCase(),
                                  style: theme.textTheme.titleLarge,
                                  maxLines:
                                      2, // Caps rendering at two lines max
                                  overflow: TextOverflow
                                      .ellipsis, // Clips extra text with "..."
                                ),
                                Text(
                                  "${equipment.owner?.displayName}"
                                      .toUpperCase(),
                                  style: theme.textTheme.titleMedium,
                                  maxLines:
                                      2, // Caps rendering at two lines max
                                  overflow: TextOverflow
                                      .ellipsis, // Clips extra text with "..."
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// Pricing
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          l10n.servicePlan,
                          style: theme.textTheme.headlineLarge,
                        ),
                      ),

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
                                setState(() => selectedPriceIndex = index);
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
                                    : theme.cardColor,
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
                                "${entry?.price} ₸ / ${entry?.priceRate}",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      /// Address & Schedule
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          l10n.addressAndSchedule,
                          style: theme.textTheme.headlineLarge,
                        ),
                      ),

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
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: DateTimeButton(
                              icon: Icons.calendar_today_rounded,
                              label: bookingState.selectedDate == null
                                  ? l10n.selectDate
                                  : DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(bookingState.selectedDate!),
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
                                          (bookingState.selectedDate ??
                                                  initialTargetDateTime)
                                              .isBefore(DateTime.now())
                                          ? DateTime.now()
                                          : (bookingState.selectedDate ??
                                                initialTargetDateTime),
                                      minimumDate: DateTime.now(),
                                      maximumDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                      onDateTimeChanged: (date) {
                                        bookingNotifier.setDate(date);
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
                              label: bookingState.selectedTime == null
                                  ? l10n.selectTime
                                  : DateFormat.jm().format(
                                      bookingState.selectedTime!,
                                    ),
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
                                          bookingState.selectedTime ??
                                          initialTargetDateTime,
                                      onDateTimeChanged: (time) {
                                        bookingNotifier.setTime(time);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// 4. ADDITIONAL NOTES
                      Text(
                        l10n.noteToOperator,
                        style: theme.textTheme.headlineLarge,
                      ),

                      const SizedBox(height: 10),

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

                      const SizedBox(height: 20),

                      PrimaryButton(
                        label: "Place Order",
                        onPressed:
                            (bookingState.selectedLocationId == null ||
                                bookingState.selectedDate == null)
                            ? null
                            : _onPressed,
                        isLoading: bookingState.isSubmitting,
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

Widget _buildCenteredFallback({
  required IconData icon,
  required String message,
}) {
  return SizedBox(
    height: 400,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
          ),
        ],
      ),
    ),
  );
}
