import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/chat/utils/chat_navigation.dart';

class ClientBookingTile extends ConsumerWidget {
  final BookingModel booking;
  const ClientBookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final minutesLeft = getRemainingMinutes(booking.bookedAt);
    final bookingData = getBookingMessage(booking.bookedOn, booking.bookedAt);

    final String message = bookingData?['message'] ?? 'Status unavailable';
    // final String status = bookingData?['status'] ?? 'unknown';

    final displayMessage = booking.status == BookingStatus.created.name
        ? "$minutesLeft min left"
        : (booking.status == BookingStatus.confirmed.name)
        ? message
        : "";

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // CRITICAL: Hugs contents
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getBookingStatus(booking.status),
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
                // Equipment Image and info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130, // Fixed width
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            booking.equipment.imageUrl ?? "",
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            ),
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
                            booking.equipment.name.toUpperCase(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            booking.equipment.model.toUpperCase(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            booking.equipment.owner?.displayName ?? "",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    BookingStatusBadge(status: booking.status),
                  ],
                ),

                const SizedBox(height: 16),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InfoTile(
                          label: 'Location',
                          value: booking.location.street,
                          onTap: () =>
                              showLocationSheet(context, booking.location),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoTile(
                          label: 'Date & time',
                          value: booking.bookedOn != null
                              ? DateFormat(
                                  'dd MMM yyyy • HH:mm',
                                ).format(booking.bookedOn!)
                              : "PENDING",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Second Row of InfoTiles
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InfoTile(
                          label:
                              booking.equipment.category?.capacityUnit ??
                              "Capacity",
                          value:
                              "${booking.equipment.capacity.toUpperCase()} ${(booking.equipment.category?.capacityUnit ?? "").toUpperCase()}",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoTile(
                          label: 'Offered rate',
                          value:
                              "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate)}",
                          isHighlighted: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Comment Tile (Full Width - No Expanded wrapper)
                if (booking.comment != null && booking.comment!.isNotEmpty)
                  InfoTile(label: 'Comment', value: booking.comment!),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Chat Button
                    Expanded(
                      child: ActionButton(
                        icon: Icons.chat,
                        color: Colors.green,
                        onTap: () async {
                          await openChatFromLink(
                            context: context,
                            ref: ref,
                            isOwner: false,
                            bookingId: booking.id,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: ActionButton(
                        icon: Icons.close,
                        color: Colors.redAccent,
                        onTap: () {
                          _handleCancel(context, ref, booking);
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
) async {
  final theme = Theme.of(context);
  final notifier = ref.read(bookingProvider.notifier);

  final modalTitle = booking.status.toUpperCase() == "CREATED"
      ? "Reject Order"
      : "Cancel Order";

  final modalText = booking.status.toUpperCase() == "CREATED"
      ? "Are you sure you want to reject this order?"
      : "Are you sure you want to cancel this order?";

  final submitButton = booking.status.toUpperCase() == "CREATED"
      ? "Yes, Reject"
      : "Yes, Cancel";

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
            child: const Text("No"),
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

  // ⏱️ Time restriction check
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

    if (res == true) {
      Navigator.pop(context); // close sheet

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order Cancelled")));
    }
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       "You can only cancel within $cancelWindowMinutes minutes of booking.",
    //     ),
    //   ),
    // );
    return;
  }

  // Open reason sheet
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return CancelBookingSheet(booking: booking, useCase: "client");
    },
  );
}
