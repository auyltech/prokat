import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientDashboardBookingTile extends ConsumerWidget {
  final BookingModel booking;

  const ClientDashboardBookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // 1. Top Section: Primary Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130, // Fixed width
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: OptimizedNetworkImage(
                      imageUrl: booking.equipment?.imageUrl ?? "",
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.image,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.equipment?.name ?? "", // ?? 'Unknown Equipment',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      booking.owner?.displayName ??
                          "", // ?? 'Unknown Equipment',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              BookingStatusBadge(status: booking.status),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 2,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),

          // Meta Info Grid
          _buildMetaRow(
            context,
            Icons.location_on_outlined,
            l10n.unknownLocation,
            theme.primaryColor,
          ),

          const SizedBox(height: 6),

          _buildMetaRow(
            context,
            Icons.calendar_today_outlined,
            booking.bookedOn != null
                ? DateFormat('MMM dd, yyyy • hh:mm a').format(booking.bookedOn!)
                : "Date not set",
            Colors.orange,
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 2,
              thickness: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),

          // 2. Bottom Section: Pricing Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Go to chat
              Expanded(
                flex: 1,
                child: ActionButton(
                  icon: Icons.chat,
                  onPressed: () {
                    context.push('${AppRoutes.chat}/${booking.chatId}');
                  },
                ),
              ),

              Expanded(
                flex: 3,
                child: RichText(
                  textAlign: TextAlign.end,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: formatPrice(
                          booking.price,
                        ), // Switched to Tenge symbol for consistency
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: getPriceRate(booking.priceRate, l10n: l10n),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
