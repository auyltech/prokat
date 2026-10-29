import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
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
        return const Color.fromARGB(255, 32, 57, 141);
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
      case BookingStatus.failed:
        return const Color.fromARGB(255, 179, 0, 0);
      case BookingStatus.draft:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final palette = ProkatFlowScope.maybeOf(context);
    if (palette != null) {
      final foreground = switch (status) {
        BookingStatus.confirmed => palette.success,
        BookingStatus.completed || BookingStatus.reviewed => palette.primary,
        BookingStatus.cancelled ||
        BookingStatus.rejected ||
        BookingStatus.failed => Theme.of(context).colorScheme.error,
        BookingStatus.created => palette.primary,
        BookingStatus.draft => palette.secondary,
      };
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(AppDimens.r10$base),
          border: Border.all(color: foreground.withValues(alpha: .22)),
        ),
        child: Text(
          getBookingStatus(status, l10n: l10n),
          style: AppFonts.body14SemiBold(context).copyWith(color: foreground),
        ),
      );
    }

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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
