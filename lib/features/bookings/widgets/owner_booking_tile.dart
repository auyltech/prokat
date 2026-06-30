import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_chat_button.dart';
import 'package:prokat/features/bookings/widgets/owner_cancel_booking_button.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerBookingTile extends ConsumerWidget {
  final BookingModel booking;

  const OwnerBookingTile({super.key, required this.booking});

  void handleAccept(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept Order?'),
          content: const Text('Are you sure you want to accept this order?'),
          actions: [
            TextButton(
              onPressed: () {
                if (context.mounted && context.canPop()) {
                  context.pop();
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (context.mounted && context.canPop()) {
                  context.pop();
                }
                await ref
                    .read(bookingProvider.notifier)
                    .updateBookingStatus(
                      id: booking.id,
                      status: BookingStatus.confirmed.name,
                    );
              },
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // final minutesLeft = getRemainingMinutes(booking.createdAt);

    final canReview =
        booking.status == BookingStatus.completed &&
        !(booking.myReviewId != null && booking.myReviewId?.isNotEmpty == true);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // Client Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserInfoTile(user: booking.client),

              Spacer(),

              BookingStatusBadge(status: booking.status),
            ],
          ),

          // TODO: Add minutes left
          // Text(
          //   "$minutesLeft m left",
          //   style: theme.textTheme.bodySmall?.copyWith(
          //     color: colorScheme.error,
          //   ),
          // ),
          const SizedBox(height: 16),

          EquipmentInfoTile(equipment: booking.equipment),

          const SizedBox(height: 16),

          // Location, Date & Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InfoTile(
                  label: l10n.location,
                  value: booking.location?.street ?? "",
                  onTap: () {
                    final location = booking.location;

                    location == null
                        ? null
                        : showLocationSheet(context, location);
                  },
                  icon: Icons.map_outlined,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: InfoTile(
                  icon: Icons.timelapse,
                  label: "Date & Time",
                  value: formatDateTime(booking.bookedOn, booking.bookedAt),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (booking.comment != null && booking.comment!.isNotEmpty) ...[
            Row(
              children: [
                InfoTile(label: l10n.comments, value: booking.comment!),
              ],
            ),

            const SizedBox(height: 16),
          ],

          // SECTION 4: Financial Value & Direct Call-to-Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InfoTile.ghost(label: "Price", value: formatPrice(booking.price)),

              Spacer(),

              Row(
                children: [
                  if (booking.status == BookingStatus.created ||
                      booking.status == BookingStatus.confirmed) ...[
                    OwnerCancelBookingButton(booking: booking),
                    const SizedBox(width: 8),
                  ],

                  OwnerBookingChatButton(booking: booking),
                  const SizedBox(width: 12),

                  if (booking.status == BookingStatus.created) ...[
                    ActionButton(
                      label: "Accept Order",
                      onPressed: () => handleAccept(context, ref, theme),
                    ),
                  ] else if (booking.status == BookingStatus.confirmed) ...[
                    ActionButton(
                      label: 'Complete Work',
                      onPressed: () async {
                        await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: theme.colorScheme.surface,
                            title: const Text('Mark completed?'),
                            content: const Text(
                              'Client will need to confirm completion.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  if (context.mounted && context.canPop()) {
                                    context.pop();
                                  }
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (context.canPop()) {
                                    context.pop();
                                  }

                                  await ref
                                      .read(bookingProvider.notifier)
                                      .updateBookingWorkStatus(
                                        id: booking.id,
                                        workStatus: WorkStatus.completed,
                                      );
                                },
                                child: const Text('Mark completed'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else if (canReview) ...[
                    ActionButton(
                      label: "Submit Review",
                      onPressed: () async {
                        await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: theme.colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => ReviewSheet(
                            bookingId: booking.id,
                            revieweeId: booking.client?.id ?? "",
                            title: 'Review client',
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
