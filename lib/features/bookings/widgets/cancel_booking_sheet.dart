import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CancelBookingSheet extends ConsumerStatefulWidget {
  final BookingModel booking;
  final AppMode? mode;

  const CancelBookingSheet({super.key, required this.booking, this.mode});

  @override
  ConsumerState<CancelBookingSheet> createState() => CancelBookingSheetState();
}

class CancelBookingSheetState extends ConsumerState<CancelBookingSheet> {
  String? selectedReason;

  Future<void> onSubmit(AppLocalizations? l10n) async {
    final isOwner = widget.mode == AppMode.ownerMode;
    final notifier = ref.read(bookingMutationProvider.notifier);

    final status = isOwner
        ? widget.booking.status == BookingStatus.created
              ? BookingStatus.rejected
              : BookingStatus.cancelled
        : BookingStatus.cancelled;

    Navigator.pop(context);

    final result = await notifier.updateBookingStatus(
      id: widget.booking.id,
      status: status,
      cancelReason: selectedReason,
    );

    AppSnackBar.show(
      message: result.success
          ? l10n?.orderCancelled ?? "Order Cancelled"
          : "Failed to cancel order",
      isSuccess: result.success,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final bookingState = ref.watch(bookingMutationProvider);

    final isOwner = widget.mode == AppMode.ownerMode;

    final ownerCancelReasons = [
      l10n.cancelReasonClientNotRespond,
      l10n.cancelReasonEquipUnavailable,
      l10n.cancelReasonPricingIssue,
      l10n.cancelReasonSchedulingConflict,
      l10n.cancelReasonOther,
    ];

    final clientCancelReasons = [
      l10n.cancelReasonDidNotShowUp,
      l10n.cancelReasonChangedMind,
      l10n.cancelReasonEquipNotSuitable,
      l10n.cancelReasonOther,
    ];

    final sheetTitle = isOwner
        ? widget.booking.status == BookingStatus.created
              ? l10n.rejectOrder
              : l10n.cancelBooking
        : l10n.cancelBooking;

    final reasons = isOwner ? ownerCancelReasons : clientCancelReasons;

    final actionId = "booking:cancel:${widget.booking.id}";

    final action = bookingState.activeActions
        .where((item) => item.id == actionId)
        .firstOrNull;

    final isSubmitting = action == null
        ? false
        : action.status == MutationStatus.submitting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Text(
            sheetTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          ...reasons.map((reason) {
            final isSelected = selectedReason == reason;

            return GestureDetector(
              onTap: () {
                setState(() => selectedReason = reason);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceBright,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(reason, style: theme.textTheme.bodyMedium),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ActionBarButton.secondary(
                  label: l10n.goBack,
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: ActionBarButton.destructive(
                  label: widget.mode == "client"
                      ? l10n.cancelBooking
                      : widget.booking.status == BookingStatus.created
                      ? l10n.rejectOrder
                      : l10n.cancelBooking,
                  onPressed: selectedReason == null
                      ? null
                      : () => onSubmit(l10n),
                  isLoading: isSubmitting,
                  isEnabled: selectedReason != null && !isSubmitting,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
