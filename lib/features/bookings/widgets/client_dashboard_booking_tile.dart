import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';

class ClientDashboardBookingTile extends StatelessWidget {
  final BookingModel booking;

  const ClientDashboardBookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // 1. Top Section: Primary Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.equipment.name, // ?? 'Unknown Equipment',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      _StatusBadge(status: booking.status),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "CAPACITY: 10 M3", // Hardcoded per your snippet
                    style: theme.textTheme.labelMedium,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      height: 2,
                      thickness: 1,
                      color: Color.fromARGB(255, 194, 194, 194),
                    ),
                  ),

                  // Meta Info Grid
                  _buildMetaRow(
                    context,
                    Icons.location_on_outlined,
                    "Satpayeva, Atyrau",
                    theme.primaryColor,
                  ),

                  const SizedBox(height: 12),

                  _buildMetaRow(
                    context,
                    Icons.calendar_today_outlined,
                    booking.bookedOn != null
                        ? DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          ).format(booking.bookedOn!)
                        : "Date not set",
                    Colors.orange,
                  ),
                ],
              ),
            ),

            // 2. Bottom Section: Pricing Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("TOTAL PRICE", style: theme.textTheme.bodyMedium),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              "${booking.price} ₸ ", // Switched to Tenge symbol for consistency
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        TextSpan(
                          text: "/ ${booking.priceRate}",
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context,
    IconData icon,
    String text,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    switch (status.toUpperCase()) {
      case 'CREATED':
        baseColor = Colors.orange;
        break;
      case 'CONFIRMED':
        baseColor = Colors.green;
        break;
      case 'COMPLETED':
        baseColor = Colors.blue;
        break;
      case 'CANCELLED':
        baseColor = Colors.red;
        break;
      default:
        baseColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: baseColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: baseColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
