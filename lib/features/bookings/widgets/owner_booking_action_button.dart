import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';

class OwnerBookingActionButton extends StatelessWidget {
  final BookingModel booking;

  const OwnerBookingActionButton({super.key, required this.booking});

  // Determines the appropriate explicit action text based on the order lifecycle state
  String _getActionText(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'Start Work';
      case 'IN_PROGRESS':
        return 'Complete Work';
      case 'COMPLETED':
        return 'View Summary';
      default:
        return 'Update Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final buttonText = _getActionText(booking.status);

    return FilledButton(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => BookingStatusSheet(booking: booking),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(100, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
