import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class ClientBookingTile extends ConsumerWidget {
  final BookingModel booking;
  const ClientBookingTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Data parsing helpers inherited from your previous layout structure
    final minutesLeft = getRemainingMinutes(booking.bookedAt);
    final bookingData = getBookingMessage(booking.bookedOn, booking.bookedAt);
    final String message = bookingData?['message'] ?? 'Status unavailable';

    final displayMessage = booking.status == BookingStatus.created
        ? l10n.minutesLeft(minutesLeft)
        : (booking.status == BookingStatus.confirmed)
        ? message
        : "";

    final canReview =
        booking.status == BookingStatus.completed &&
        booking.myReviewId != null &&
        booking.myReviewId!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner Profile & Status Badging Row
          Row(
            children: [
              UserInfoTile(user: booking.owner),

              Spacer(),

              // Text(displayMessage),
              BookingStatusBadge(status: booking.status),
            ],
          ),

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
            InfoTile(label: l10n.comments, value: booking.comment!),

            const SizedBox(height: 16),
          ],

          // 4. Footer Section: Pricing Breakdown & Horizontal Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.offeredRate.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate, l10n: l10n)}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0D47A1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              // Conditional Action Buttons Row Block
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ([
                    BookingStatus.created,
                    BookingStatus.confirmed,
                  ].contains(booking.status)) ...[
                    ActionButton.danger(
                      label: "Cancel",
                      onPressed: () {
                        _handleCancel(context, ref, booking, l10n);
                      },
                    ),

                    const SizedBox(width: 8),

                    ActionButton.ghost(
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () {
                        context.push('${AppRoutes.chat}/${booking.chatId}');
                      },
                    ),
                  ] else if (canReview) ...[
                    ActionButton(
                      icon: Icons.reviews,
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
                            title: 'Review owner',
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    Text(""),
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

Future<void> _handleCancel(
  BuildContext context,
  WidgetRef ref,
  BookingModel booking,
  AppLocalizations l10n,
) async {
  final theme = Theme.of(context);
  final notifier = ref.read(bookingProvider.notifier);

  final modalTitle = booking.status == BookingStatus.created
      ? l10n.cancelBooking
      : l10n.rejectOrder;

  final modalText = booking.status == BookingStatus.created
      ? l10n.cancelOrderQuestion
      : l10n.rejectOrderQuestion;

  final submitButton = booking.status == BookingStatus.created
      ? l10n.yesCancel
      : l10n.yesReject;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(modalTitle, style: theme.textTheme.titleMedium),
        content: Text(modalText, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(submitButton),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  final createdAt = booking.createdAt ?? DateTime(2026);
  final now = DateTime.now();
  const cancelWindowMinutes = 10;
  final difference = now.difference(createdAt).inMinutes;

  if (difference < cancelWindowMinutes) {
    final res = await notifier.updateBookingStatus(
      id: booking.id,
      status: "CANCELLED",
      workStatus: "cancelled in $difference minutes",
    );

    if (res == true && context.mounted) {
      Navigator.pop(context);
      AppSnackBar.show(context, message: l10n.orderCancelled);
    }
    return;
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CancelBookingSheet(booking: booking, mode: "client"),
  );
}
