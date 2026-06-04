import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingStatusBadge extends StatelessWidget {
  final BookingStatus status;

  const BookingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getBookingColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: getBookingColor(status).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        getBookingStatus(status, l10n: l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: getBookingColor(status),
        ),
      ),
    );
  }
}
