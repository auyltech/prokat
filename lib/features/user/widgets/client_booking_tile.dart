import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
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

    final displayMessage = booking.status == BookingStatus.created.name
        ? l10n.minutesLeft(minutesLeft)
        : (booking.status == BookingStatus.confirmed.name)
        ? message
        : "";

    final ownerName = booking.owner?.displayName;
    final displayName = (ownerName == null || ownerName.isEmpty)
        ? "Owner Name"
        : booking.owner?.displayName ?? "";

    final canReview =
        booking.status == "COMPLETED" &&
            booking.myReviewId != null &&
            booking.myReviewId!.isNotEmpty ||
        booking.status != "REVIEWED";

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
          // 1. Top Section: User Profile & Status Badging Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 0, 89, 156),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 22, 22, 22),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "4.7",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "• 13 orders",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        if (displayMessage.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            "• $displayMessage",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFC62828),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  getBookingStatus(booking.status, l10n: l10n).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3F51B5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Middle Section: Grey Wrapper Card for Equipment Data
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: OptimizedNetworkImage(
                      imageUrl: booking.equipment?.imageUrl ?? "",
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.local_shipping,
                      backgroundColor: const Color(0xFFE0E0E0),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF212121),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.equipment?.model?.toUpperCase() ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Lower Section: Split Info Fields (Delivery vs Date Time)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.location.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        final location = booking.location;

                        location == null
                            ? null
                            : showLocationSheet(context, location);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 15,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.location?.street ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF424242),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dateAndTime.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.bookedOn != null
                          ? DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(booking.bookedOn!)
                          : "PENDING",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF424242),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (booking.comment != null && booking.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "${l10n.comments}: ${booking.comment}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),

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
                  if (booking.status == "CREATED" ||
                      booking.status == "CONFIRMED") ...[
                    // Go to Chat Button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _handleCancel(context, ref, booking, l10n);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cancel / Primary Action Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        context.push('${AppRoutes.chat}/${booking.chatId}');
                      },
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ] else if (canReview) ...[
                    Text("Leave Review"),
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
      ? l10n.rejectOrder
      : l10n.cancelBooking;

  final modalText = booking.status == BookingStatus.created
      ? l10n.rejectOrderQuestion
      : l10n.cancelOrderQuestion;

  final submitButton = booking.status == BookingStatus.created
      ? l10n.yesReject
      : l10n.yesCancel;

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
    builder: (context) =>
        CancelBookingSheet(booking: booking, mode: "client"),
  );
}
