import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:prokat/core/widgets/ui_kit/toasts/app_toast.dart";
import "package:prokat/core/widgets/ui_kit/controls/buttons/app_label_button.dart";
import "package:prokat/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart";
import "package:prokat/features/appstartup/app_mode_storage.dart";
import "package:prokat/features/bookings/models/booking_model.dart";
import "package:prokat/features/bookings/models/booking_status.dart";
import "package:prokat/features/bookings/providers/booking_mutation_provider.dart";
import "package:prokat/features/bookings/widgets/booking_status_sheet.dart";
import "package:prokat/features/bookings/widgets/cancel_booking_sheet.dart";
import "package:prokat/features/owner/owner_offline_guard.dart";
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

  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await ensureOwnerOnline(
      context,
      ref,
      message: l10n.ownerOfflineMustBeOnlineToAcceptOrder,
    )) {
      return;
    }
    if (!context.mounted) return;

    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: l10n.confirmOrder,
      description: l10n.acceptBookingFor(booking.equipment?.name ?? ''),
      primaryLabel: l10n.confirm,
      secondaryLabel: l10n.cancel,
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(bookingMutationProvider.notifier)
        .updateBookingStatus(id: booking.id, status: BookingStatus.confirmed);
    if (!context.mounted) return;
    AppToast.show(
      message: result.success
          ? l10n.orderConfirmed
          : ownerOfflineActionErrorMessage(
              l10n: l10n,
              errorCode: result.errorCode,
              fallback: l10n.failedToConfirmOrder,
            ),
      type: result.success ? AppToastType.success : AppToastType.error,
    );
    if (result.success) onActionCompleted?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AppLabelButton(
              title: booking.status == BookingStatus.created
                  ? l10n.decline
                  : l10n.cancel,
              onTap: () => _handleCancel(context, ref, booking, l10n),
              isExpanded: true,
              variant: AppLabelButtonVariant.outlined,
              tone: AppLabelButtonTone.destructive,
            ),
          ),

          const SizedBox(width: 8),

          if (booking.status == BookingStatus.created) ...[
            Expanded(
              child: AppLabelButton(
                title: l10n.counter,
                onTap: () => _handleCounterOffer(context),
                isExpanded: true,
                variant: AppLabelButtonVariant.outlined,
              ),
            ),

            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: AppLabelButton(
                title: l10n.acceptOrder,
                onTap: () => unawaited(_handleAccept(context, ref)),
                isExpanded: true,
                tone: AppLabelButtonTone.success,
              ),
            ),
          ] else
            Expanded(
              child: AppLabelButton(
                title: l10n.startWork,
                onTap: () => BookingStatusSheet.show(context, booking: booking),
                isExpanded: true,
                variant: AppLabelButtonVariant.outlined,
              ),
            ),
        ],
      ),
    );
  }

  void _handleCounterOffer(BuildContext context) {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => CounterOfferSheet(
          bookingId: booking.id,
          initialPrice: booking.price,
          initialPriceRate: booking.priceRate,
          mode: AppMode.clientMode,
        ),
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
    final notifier = ref.read(bookingMutationProvider.notifier);

    final modalTitle = booking.status == BookingStatus.created
        ? l10n.rejectOrder
        : l10n.cancelBooking;

    final modalText = booking.status == BookingStatus.created
        ? l10n.rejectOrderQuestion
        : l10n.cancelOrderQuestion;

    final submitButton = booking.status == BookingStatus.created
        ? l10n.yesReject
        : l10n.yesCancel;

    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: modalTitle,
      description: modalText,
      primaryLabel: submitButton,
      secondaryLabel: l10n.no,
      isDestructivePrimary: true,
    );

    if (confirmed != true) return;

    final createdAt = booking.createdAt ?? DateTime(2026);
    final now = DateTime.now();
    const cancelWindowMinutes = 10;
    final difference = now.difference(createdAt).inMinutes;

    if (difference < cancelWindowMinutes) {
      final res = await notifier.updateBookingStatus(
        id: booking.id,
        status: BookingStatus.cancelled,
        cancelReason: "cancelled in $difference minutes",
      );

      if (res.success == true) {
        if (!context.mounted) return;
        Navigator.pop(context);

        if (!context.mounted) return;
        AppToast.show(message: l10n.orderCancelled, type: AppToastType.success);
      }
      return;
    }

    if (!context.mounted) return;
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => CancelBookingSheet(booking: booking),
      ),
    );
  }
}
