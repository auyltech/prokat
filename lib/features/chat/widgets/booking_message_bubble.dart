import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/bookings/widgets/show_location_sheet.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/equipment/widgets/equipment_details_sheet.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingMessageBubble extends ConsumerStatefulWidget {
  final AppMode mode;
  final ChatMessageModel message;
  final ChatModel? currentChat;

  const BookingMessageBubble({
    super.key,
    required this.message,
    required this.mode,
    this.currentChat,
  });

  @override
  ConsumerState<BookingMessageBubble> createState() =>
      _BookingMessageBubbleState();
}

class _BookingMessageBubbleState extends ConsumerState<BookingMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final booking = widget.currentChat?.booking;

    if (booking == null) {
      return Text(l10n.errorLoadingBooking);
    }

    final equipment = booking.equipment;
    final location = booking.location;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row (Order Info Text & Colored Status Badge)
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.newOrder,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

              Spacer(),

              BookingStatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Equipment Body (Triggers the external Details Sheet)
          InkWell(
            onTap: () {
              EquipmentDetailsSheet.show(
                context,
                name: equipment?.name,
                model: equipment?.model,
                plateNumber: equipment?.plateNumber,
                imageUrl: equipment?.imageUrl,
              );
            },
            borderRadius: const BorderRadius.all(Radius.zero),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (equipment?.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      equipment!.imageUrl!,
                      width: 80,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 54,
                        height: 40,
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.image,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 54,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment?.name ?? l10n.unknownEquipment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        equipment?.model ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (location != null) ...[
            InfoTile(
              icon: Icons.location_on_outlined,
              // label: "Location",
              value: booking.location?.street ?? "",
              onTap: () => showLocationSheet(context, location),
            ),
            const SizedBox(height: 8),
          ],

          //  Location
          Row(
            children: [
              // Date Time
              InfoTile(
                icon: Icons.event_outlined,
                // label: "Date & time",
                value: () {
                  if (booking.bookedOn == null) return "TBD";

                  // 1. Format the date part cleanly (e.g., "02 Jun 2026")
                  final dateStr = DateFormat(
                    'dd MMM yyyy',
                  ).format(booking.bookedOn!.toLocal());

                  // 3. Return just the date if no time was specified
                  return dateStr;
                }(),
              ),

              if (booking.bookedAt != null) ...[
                const SizedBox(width: 8),

                InfoTile(
                  icon: Icons.access_time_outlined,
                  value: booking.bookedAt != null
                      ? DateFormat('HH:mm').format(booking.bookedAt!.toLocal())
                      : "",
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              InfoTile(
                icon: LucideIcons.coins,
                // label: l10n.price,
                value:
                    "${formatPrice(booking.price)} ${getPriceRate(booking.priceRate, l10n: l10n)}",
              ),

              Spacer(),

              // Cancel Order
              if ([
                    BookingStatus.created,
                    BookingStatus.confirmed,
                  ].contains(booking.status) &&
                  booking.workStatus != WorkStatus.completed) ...[
                if (ref
                        .watch(bookingMutationProvider)
                        .isActionActive("booking:${booking.id}:cancel") ||
                    ref
                        .watch(bookingMutationProvider)
                        .isActionActive("booking:${booking.id}:reject"))
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: theme.colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => CancelBookingSheet(
                        booking: booking,
                        mode: widget.mode,
                      ),
                    ),
                    icon: Icon(
                      LucideIcons.x,
                      size: 25,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],

              // Create Price Negotiation
              if (booking.status == BookingStatus.created) ...[
                if (ref
                    .watch(bookingMutationProvider)
                    .isActionActive("price:create"))
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () async {
                      await CounterOfferSheet.show(
                        context,
                        bookingId: booking.id,
                        chatId: widget.message.chatId,
                        initialPrice: booking.price,
                        initialPriceRate: booking.priceRate,
                        mode: widget.mode,
                      );
                    },
                    icon: Icon(
                      LucideIcons.coins,
                      size: 25,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],

              // Update Work Status
              if (widget.mode == AppMode.ownerMode &&
                  booking.status == BookingStatus.created) ...[
                if (ref
                    .watch(bookingMutationProvider)
                    .isActionActive(
                      "booking:${booking.id}:update:${BookingStatus.confirmed}",
                    ))
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.colorScheme.surface,
                          title: Text(l10n.acceptOrderQuestion),
                          content: Text(l10n.acceptOrderConfirmation),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),

                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context, true);

                                final result = await ref
                                    .read(bookingMutationProvider.notifier)
                                    .updateBookingStatus(
                                      id: booking.id,
                                      status: BookingStatus.confirmed,
                                    );

                                AppSnackBar.show(
                                  message: result.success
                                      ? l10n.orderConfirmed
                                      : l10n.failedToConfirmOrder,
                                  isSuccess: result.success,
                                  isError: !result.success,
                                );
                              },
                              child: Text(l10n.accept),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      LucideIcons.check,
                      size: 25,
                      color: Colors.green[800],
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
