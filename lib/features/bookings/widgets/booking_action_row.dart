import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:prokat/features/bookings/models/booking_model.dart";
import "package:prokat/features/bookings/models/booking_status.dart";
import "package:prokat/features/bookings/state/booking_provider.dart";
import "package:prokat/features/bookings/widgets/booking_status_sheet.dart";
import "package:prokat/features/bookings/widgets/cancel_booking_sheet.dart";
import "package:prokat/features/bookings/widgets/counter_offer_sheet.dart";
import "package:prokat/features/chat/state/chat_provider.dart";

class BookingActionRow extends ConsumerWidget {
  final BookingModel booking;
  final VoidCallback? onActionCompleted;

  const BookingActionRow({
    super.key,
    required this.booking,
    this.onActionCompleted,
  });

  void _handleAccept(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookingProvider.notifier);
    final chatNotifier = ref.watch(chatProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Order"),
        content: Text(
          "Are you sure you want to accept the booking for ${booking.equipment?.name}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // 2. Update backend
              await notifier.updateBookingStatus(
                id: booking.id,
                status: BookingStatus.confirmed.name,
              );

              await chatNotifier.reloadChat(booking.chatId ?? "");

              // 3. Close dialog
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Reject Button
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleCancel(context, ref, booking),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                booking.status.toUpperCase() == "CREATED"
                    ? 'Decline'
                    : 'Cancel',
              ),
            ),
          ),

          const SizedBox(width: 8),
          // Counter Offer Button
          if (booking.status.toLowerCase() == BookingStatus.created.name)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleCounterOffer(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Counter"),
              ),
            ),

          if (booking.status.toLowerCase() == BookingStatus.created.name)
            const SizedBox(width: 8),

          if (booking.status.toLowerCase() == BookingStatus.created.name)
            // Accept Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _handleAccept(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text("Accept Order"),
              ),
            )
          else
            Expanded(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: theme.colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => BookingStatusSheet(booking: booking),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.primaryColor)
                  ),
                  elevation: 0,
                ),
                child: Text('Start Work'),
              ),
            ),
        ],
      ),
    );
  }

  void _handleCounterOffer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CounterOfferSheet(booking: booking),
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final theme = Theme.of(context);
    final notifier = ref.read(bookingProvider.notifier);
    final chatNotifier = ref.watch(chatProvider.notifier);

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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

        await chatNotifier.reloadChat(booking.chatId ?? "");

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
        return CancelBookingSheet(booking: booking);
      },
    );
  }
}
