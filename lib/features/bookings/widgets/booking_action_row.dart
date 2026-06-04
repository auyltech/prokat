import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:prokat/features/bookings/models/booking_model.dart";
import "package:prokat/features/bookings/models/booking_status.dart";
import "package:prokat/features/bookings/state/booking_provider.dart";
import "package:prokat/features/bookings/widgets/booking_status_sheet.dart";
import "package:prokat/features/bookings/widgets/cancel_booking_sheet.dart";
import "package:prokat/features/chat/state/chat_provider.dart";
import "package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart";
import "package:prokat/l10n/app_localizations.dart";

class BookingActionRow extends ConsumerWidget {
  final BookingModel booking;
  final VoidCallback? onActionCompleted;

  const BookingActionRow({
    super.key,
    required this.booking,
    this.onActionCompleted,
  });

  void _handleAccept(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(bookingProvider.notifier);
    final chatNotifier = ref.watch(chatProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmOrder),
        content: Text(l10n.acceptBookingFor(booking.equipment?.name ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.updateBookingStatus(
                id: booking.id,
                status: BookingStatus.confirmed.name,
              );
              await chatNotifier.reloadChat(booking.chatId ?? "");
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _handleCancel(context, ref, booking, l10n),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                booking.status == BookingStatus.created
                    ? l10n.decline
                    : l10n.cancel,
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (booking.status == BookingStatus.created) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleCounterOffer(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(l10n.counter),
              ),
            ),

            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _handleAccept(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(l10n.acceptOrder),
              ),
            ),
          ] else
            Expanded(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: theme.colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => BookingStatusSheet(booking: booking),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.primaryColor),
                  ),
                  elevation: 0,
                ),
                child: Text(l10n.startWork),
              ),
            ),
        ],
      ),
    );
  }

  void _handleCounterOffer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CounterOfferSheet(
        bookingId: booking.id,
        initialPrice: booking.price,
        initialPriceRate: booking.priceRate,
        counterType: "CLIENT_COUNTER",
      ),
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
    AppLocalizations l10n,
  ) async {
    final theme = Theme.of(context);
    final notifier = ref.read(bookingProvider.notifier);
    final chatNotifier = ref.watch(chatProvider.notifier);

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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

      if (res == true) {
        if (!context.mounted) return;
        Navigator.pop(context);
        await chatNotifier.reloadChat(booking.chatId ?? "");
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.orderCancelled)));
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
      builder: (context) => CancelBookingSheet(booking: booking),
    );
  }
}
