import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    final bookingNotifier = ref.read(bookingProvider.notifier);

    final res = await bookingNotifier.createBooking();

    if (res == true) {
      AppSnackBar.show(context, message: "Order created", isSuccess: true);

      if (mounted && context.canPop()) context.pop();
    } else {
      AppSnackBar.show(
        context,
        message: "Failed to create order",
        isError: true,
      );
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

    final state = ref.watch(equipmentProvider);
    final locationState = ref.watch(locationProvider);

    final selectedAddress = locationState.selectedAddress;

    if (state.renterEquipment.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

                      Row(
                        children: [
                          Expanded(
                            child: DateTimeButton(
                              icon: Icons.calendar_today_rounded,
                              label: bookingState.selectedDate == null
                                  ? l10n.date
                                  : DateFormat(
                                      'MMM dd',
                                    ).format(bookingState.selectedDate!),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (date != null) {
                                  bookingNotifier.setDate(date);
                                }
                              },
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: DateTimeButton(
                              icon: Icons.access_time_rounded,
                              label: bookingState.selectedTime == null
                                  ? l10n.time
                                  : TimeOfDay.fromDateTime(
                                      bookingState.selectedTime!,
                                    ).format(context),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  final now = DateTime.now();
                                  bookingNotifier.setTime(
                                    DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      time.hour,
                                      time.minute,
                                    ),
                                  );
                                }
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
                        isLoading: bookingState.isLoading,
                      ),

                      /// 5. ACTION FOOTER
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: 58,
                      //   child: ElevatedButton(
                      //     onPressed:
                      //         ,
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: theme.colorScheme.primary,
                      //       foregroundColor: theme.colorScheme.onPrimary,
                      //       disabledBackgroundColor: theme.colorScheme.secondary
                      //           .withValues(alpha: 0.5),
                      //       disabledForegroundColor:
                      //           theme.colorScheme.onSurface,
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(20),
                      //       ),
                      //       elevation: 0,
                      //     ),
                      //     child: Text(
                      //       ,
                      //       style: theme.textTheme.bodyLarge?.copyWith(
                      //         fontWeight: FontWeight.bold,
                      //         color: theme.colorScheme.onPrimary,
                      //         letterSpacing: 1.2,
                      //       ),
                      //     ),
                      //   ),
                      // ),
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
