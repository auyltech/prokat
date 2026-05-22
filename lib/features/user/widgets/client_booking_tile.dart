import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class ClientBookingTile extends ConsumerWidget {
  final BookingModel booking;
  const ClientBookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final minutesLeft = getRemainingMinutes(booking.bookedAt);
    final bookingData = getBookingMessage(booking.bookedOn, booking.bookedAt);

    final String message = bookingData?['message'] ?? 'Status unavailable';

    final displayMessage = booking.status == BookingStatus.created.name
        ? l10n.minutesLeft(minutesLeft)
        : (booking.status == BookingStatus.confirmed.name)
        ? message
        : "";

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getBookingStatus(booking.status, l10n: l10n),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  displayMessage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: OptimizedNetworkImage(
                            imageUrl: booking.equipment?.imageUrl ?? "",
                            fit: BoxFit.cover,
                            fallbackIcon: Icons.image,
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.equipment?.name?.toUpperCase() ?? "",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            booking.equipment?.model?.toUpperCase() ?? "",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            booking.equipment?.ownerName ?? "",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InfoTile(
                          label: l10n.location,
                          value: booking.location.street,
                          onTap: () => showLocationSheet(context, booking.location),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoTile(
                          label: l10n.dateAndTime,
                          value: booking.bookedOn != null
                              ? DateFormat('dd MMM yyyy • HH:mm').format(booking.bookedOn!)
                              : "PENDING",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InfoTile(
                          label: l10n.offeredRate,
                          value: "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate, l10n: l10n)}",
                          isHighlighted: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (booking.comment != null && booking.comment!.isNotEmpty)
                  InfoTile(label: l10n.comments, value: booking.comment!),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        icon: Icons.chat,
                        color: Colors.green,
                        onTap: () {
                          context.push('${AppRoutes.chat}/${booking.chatId}');
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: ActionButton(
                        icon: Icons.close,
                        color: Colors.redAccent,
                        onTap: () {
                          _handleCancel(context, ref, booking, l10n);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _handleCancel(
  BuildContext context,
  WidgetRef ref,
  BookingModel booking,
  AppLocalizations l10n,
) async {
  final theme = Theme.of(context);
  final notifier = ref.read(bookingProvider.notifier);

  final modalTitle = booking.status.toUpperCase() == "CREATED"
      ? l10n.rejectOrder
      : l10n.cancelBooking;

  final modalText = booking.status.toUpperCase() == "CREATED"
      ? l10n.rejectOrderQuestion
      : l10n.cancelOrderQuestion;

  final submitButton = booking.status.toUpperCase() == "CREATED"
      ? l10n.yesReject
      : l10n.yesCancel;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(modalTitle, style: theme.textTheme.titleMedium),
        content: Text(modalText, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(submitButton),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  final createdAt = booking.createdAt ?? DateTime(2026);
  final now = DateTime.now();
  const cancelWindowMinutes = 10;
  final difference = now.difference(createdAt).inMinutes;

  if (difference < cancelWindowMinutes) {
    final res = await notifier.updateBookingStatus(
      id: booking.id,
      status: "CANCELLED",
      workStatus: "cancelled in $difference minutes",
    );

    if (res == true && context.mounted) {
      Navigator.pop(context);
      AppSnackBar.show(context, message: l10n.orderCancelled);
    }
    return;
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CancelBookingSheet(booking: booking, useCase: "client"),
  );
}
