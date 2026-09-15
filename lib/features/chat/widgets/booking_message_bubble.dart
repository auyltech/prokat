import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/core/widgets/info_tile.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart';
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
import 'package:prokat/features/owner/owner_offline_guard.dart';
import 'package:prokat/features/chat/utils/owner_offline_chat_lock.dart';
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
  bool _isOfflineLockedForBubble() {
    return isDirectBookingOwnerOfflineLock(
      ref: ref,
      mode: widget.mode,
      chat: widget.currentChat,
    );
  }

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
      padding: const EdgeInsets.all(16),
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
                color: theme.colorScheme.onPrimary,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.newOrder,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const Spacer(),

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
                    child: OptimizedNetworkImage(
                      imageUrl: equipment!.imageUrl,
                      width: 80,
                      height: 50,
                      fit: BoxFit.cover,
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
              value:
                  booking.location?.streetLine(
                    Localizations.localeOf(context).languageCode,
                  ) ??
                  "",
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
                  final dateStr = DateFormat('dd MMM yyyy')
                      .format(booking.bookedOn!.toLocal());

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

              const Spacer(),

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
                  const SizedBox(
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
              if (booking.status == BookingStatus.created &&
                  !(widget.mode == AppMode.clientMode &&
                      _isOfflineLockedForBubble())) ...[
                if (ref
                    .watch(bookingMutationProvider)
                    .isActionActive("price:create"))
                  const SizedBox(
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
                      if (widget.mode == AppMode.ownerMode) {
                        final online = await ensureOwnerOnline(
                          context,
                          ref,
                          message: l10n.ownerOfflineMustBeOnlineToBargain,
                        );
                        if (!online || !context.mounted) return;
                      }

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
                  const SizedBox(
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
                      final online = await ensureOwnerOnline(
                        context,
                        ref,
                        message: l10n.ownerOfflineMustBeOnlineToAcceptOrder,
                      );
                      if (!online || !context.mounted) return;

                      final confirmed = await AppAlertBottomSheet.show(
                        context,
                        title: l10n.acceptOrderQuestion,
                        description: l10n.acceptOrderConfirmation,
                        primaryLabel: l10n.accept,
                        secondaryLabel: l10n.cancel,
                      );

                      if (confirmed != true || !context.mounted) return;

                      final result = await ref
                          .read(bookingMutationProvider.notifier)
                          .updateBookingStatus(
                            id: booking.id,
                            status: BookingStatus.confirmed,
                          );

                      if (!context.mounted) return;
                      AppToast.show(
                        message: result.success
                            ? l10n.orderConfirmed
                            : ownerOfflineActionErrorMessage(
                                l10n: l10n,
                                errorCode: result.errorCode,
                                fallback: l10n.failedToConfirmOrder,
                              ),
                        type: result.success
                            ? AppToastType.success
                            : AppToastType.error,
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
