import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';

class OwnerDashboardBookingTile extends StatelessWidget {
  final BookingModel booking;

  const OwnerDashboardBookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final minutesLeft = getRemainingMinutes(booking.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: Renter Info & Status ---
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.renter?.displayName ?? "Unknown Renter",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      booking.location.street,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              BookingStatusBadge(
                status: booking.status,
              ), // Your existing compact badge
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),

          // --- Middle Row: Equipment & Details ---
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: OptimizedNetworkImage(
                  imageUrl: booking.equipment?.imageUrl ?? "",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.image_not_supported_outlined,
                  backgroundColor: colorScheme.surface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${booking.equipment?.name} • ${booking.equipment?.model}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.bookedOn != null
                              ? DateFormat(
                                  'dd MMM, HH:mm',
                                ).format(booking.bookedOn!)
                              : "Pending Date",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate)}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Bottom Row: Actions ---
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: minutesLeft > 0
                    ? colorScheme.primary
                    : colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                minutesLeft > 0 ? "$minutesLeft min left" : "Overdue",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: minutesLeft > 0
                      ? colorScheme.primary
                      : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),
              TextButton(
                onPressed: () {
                  /* Show Details Logic */
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colorScheme.primary,
                ),
                child: const Row(
                  children: [
                    Text(
                      "Details",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
