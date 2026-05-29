import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_accept_button.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_action_button.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_chat_button.dart';
import 'package:prokat/features/bookings/widgets/owner_cancel_booking_button.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';

class Temp extends ConsumerWidget {
  final BookingModel booking;

  const Temp({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final rating = 4.7;
    final bookingCount = 13;

    final minutesLeft = getRemainingMinutes(booking.createdAt);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Tile Header, Status, Time
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getBookingStatus(booking.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "$minutesLeft min left",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP ROW, client info
                // Header with title and offer badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: theme.primaryColor,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.client?.displayName ?? "",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$rating · $bookingCount bookings',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Booking Status Badge
                    BookingStatusBadge(status: booking.status),
                  ],
                ),

                const SizedBox(height: 16),

                // Equipment Image and Info
                Row(
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
                            booking.equipment?.name?.toUpperCase() ?? "",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            booking.equipment?.plateNumber?.toUpperCase() ?? "",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Booking Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InfoTile(
                        label: 'Location',
                        value: booking.location.street,
                        onTap: () =>
                            showLocationSheet(context, booking.location),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoTile(
                        label: 'Date & time',
                        value: booking.bookedOn != null
                            ? DateFormat(
                                'dd MMM yyyy • HH:mm',
                              ).format(booking.bookedOn!)
                            : "PENDING",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Second Row of InfoTiles
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InfoTile(label: 'Volume', value: "3 M3"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoTile(
                        label: 'Offered rate',
                        value:
                            "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate)}",
                        isHighlighted: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Comment Tile (Full Width - No Expanded wrapper)
                if (booking.comment != null && booking.comment!.isNotEmpty)
                  InfoTile(label: 'Comment', value: booking.comment!),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(child: OwnerCancelBookingButton(booking: booking)),

                    const SizedBox(width: 12),

                    // Chat Link (go to chat to send counter offers)
                    Expanded(child: OwnerBookingChatButton(booking: booking)),

                    const SizedBox(width: 12),

                    // Accept order (no counter offers)
                    if (booking.status.toUpperCase() == "CREATED")
                      Expanded(
                        child: OwnerBookingAcceptButton(booking: booking),
                      )
                    else
                      // Update Work Status
                      Expanded(
                        child: OwnerBookingActionButton(booking: booking),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
