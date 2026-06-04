import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_accept_button.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_action_button.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_chat_button.dart';
import 'package:prokat/features/bookings/widgets/owner_cancel_booking_button.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';

class OwnerBookingTile extends ConsumerWidget {
  final BookingModel booking;

  const OwnerBookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.5);

    const rating = 4.7;
    const bookingCount = 13;
    final minutesLeft = getRemainingMinutes(booking.createdAt);

    return InkWell(
      onTap: () {
        // context.push('${AppRoutes.ownerChat}/${booking.chatId}');
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: Renter Details & Time Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person_rounded,
                        color: theme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.client?.displayName ?? "",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '$rating • $bookingCount orders',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ghostGray,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "$minutesLeft m left",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    BookingStatusBadge(status: booking.status),
                  ],
                ),

                const SizedBox(height: 14),

                // SECTION 2: Equipment Visual Identifier
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: OptimizedNetworkImage(
                              imageUrl: booking.equipment?.imageUrl ?? "",
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.image,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
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
                              booking.equipment?.name?.toUpperCase() ??
                                  "UNKNOWN EQUIPMENT",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (booking.equipment?.plateNumber != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                booking.equipment!.plateNumber!.toUpperCase(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ghostGray,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // SECTION 3: Logistics (Two Column Details Layout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          final location = booking.location;

                          location == null
                              ? null
                              : showLocationSheet(context, location);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DELIVERY LOCATION",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ghostGray,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 14,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    booking.location?.street ?? "",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DATE & TIME",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ghostGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.bookedOn != null
                                ? DateFormat(
                                    'MMM dd, yyyy • hh:mm a',
                                  ).format(booking.bookedOn!)
                                : "No date specified",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                // SECTION 4: Financial Value & Direct Call-to-Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TOTAL EARNINGS",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ghostGray,
                          ),
                        ),
                        Text(
                          // Replace with your exact total price variable if different
                          formatPrice(booking.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (booking.status == BookingStatus.created ||
                            booking.status == BookingStatus.confirmed) ...[
                          OwnerCancelBookingButton(booking: booking),
                          const SizedBox(width: 8),
                        ],

                        OwnerBookingChatButton(booking: booking),
                        const SizedBox(width: 12),

                        if (booking.status == BookingStatus.created)
                          OwnerBookingAcceptButton(booking: booking)
                        else
                          OwnerBookingActionButton(booking: booking),
                      ],
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
