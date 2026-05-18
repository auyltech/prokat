import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';
// Import your BookingStatusSheet model and widget paths here
// import 'path_to_booking_model.dart';
// import 'path_to_booking_status_sheet.dart';

class OwnerBookingActionButton extends StatelessWidget {
  final dynamic booking; // Replace 'dynamic' with your actual Booking model type

  const OwnerBookingActionButton({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
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
        backgroundColor: theme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Start Work',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
