import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';

class OwnerBookingActionButton extends StatelessWidget {
  final BookingModel booking;

  const OwnerBookingActionButton({super.key, required this.booking});

  // Determines the appropriate explicit action text based on the order lifecycle state
  String _getActionText(BookingStatus status, WorkStatus workStatus) {
    if (status == BookingStatus.confirmed) {
      if (workStatus == WorkStatus.started) {
        return 'Complete Work';
      }

      return 'Start Work';
    } else if (status == BookingStatus.completed) {
      return 'View Summary';
    } else {
      return 'Update Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final buttonText = _getActionText(booking.status, booking.workStatus);

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
