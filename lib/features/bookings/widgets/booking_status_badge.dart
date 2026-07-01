import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusBadge({super.key, required this.status});

  Color get color {
    switch (status) {
      case BookingStatus.created:
        return Colors.orange;
      case BookingStatus.confirmed:
        return const Color.fromARGB(255, 0, 121, 4);
      case BookingStatus.completed:
      case BookingStatus.reviewed:
        return Color.fromARGB(255, 32, 57, 141);
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return Color.fromARGB(255, 179, 0, 0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(
        //   color: getBookingColor(status).withValues(alpha: 0.4),
        // ),
      ),
      child: Text(
        getBookingStatus(status, l10n: l10n),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
