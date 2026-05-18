import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
// Replace these with your actual import paths
// import 'path_to_booking_model.dart';
// import 'path_to_booking_provider.dart';
// import 'path_to_cancel_booking_sheet.dart';

class OwnerCancelBookingButton extends ConsumerWidget {
  final BookingModel booking;

  const OwnerCancelBookingButton({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCreatedStatus = booking.status.toUpperCase() == "CREATED";

    return OutlinedButton(
      onPressed: () => _handleCancel(context, ref, theme, isCreatedStatus),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: theme.colorScheme.error, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        isCreatedStatus ? 'Decline' : 'Cancel',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isCreatedStatus,
  ) async {
    final notifier = ref.read(bookingProvider.notifier);

    final modalTitle = isCreatedStatus ? "Reject Order" : "Cancel Order";
    final modalText = isCreatedStatus
        ? "Are you sure you want to reject this order?"
        : "Are you sure you want to cancel this order?";
    final submitButton = isCreatedStatus ? "Yes, Reject" : "Yes, Cancel";

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(submitButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Time restriction check
    final createdAt = booking.createdAt ?? DateTime.now();
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
        Navigator.pop(context); // Closes the active bottom sheet if open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Order Cancelled")));
      }
      return;
    }

    // Open reason sheet if past time window
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => CancelBookingSheet(booking: booking),
      );
    }
  }
}
