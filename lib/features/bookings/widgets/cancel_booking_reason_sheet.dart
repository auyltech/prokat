import 'package:flutter/material.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CancelBookingDecision {
  final bool confirmed;
  final String? reason;

  const CancelBookingDecision._({required this.confirmed, this.reason});

  const CancelBookingDecision.cancelled() : this._(confirmed: false);

  const CancelBookingDecision.confirmed({required String reason})
    : this._(confirmed: true, reason: reason);
}

class CancelBookingReasonSheet extends StatefulWidget {
  final BookingModel booking;
  final String? useCase;

  const CancelBookingReasonSheet({
    super.key,
    required this.booking,
    this.useCase,
  });

  @override
  State<CancelBookingReasonSheet> createState() =>
      _CancelBookingReasonSheetState();
}

class _CancelBookingReasonSheetState extends State<CancelBookingReasonSheet> {
  String? selectedReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isOwner = widget.useCase == "owner";
    final isCreated = widget.booking.status.toUpperCase() == "CREATED";

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

    final reasons = isOwner ? ownerCancelReasons : clientCancelReasons;

    final sheetTitle = isOwner && isCreated
        ? l10n.rejectOrder
        : l10n.cancelBooking;

    final confirmLabel = isOwner && isCreated
        ? l10n.rejectOrder
        : l10n.cancelBooking;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(sheetTitle, style: theme.textTheme.titleMedium),

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
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
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
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const CancelBookingDecision.cancelled(),
                      );
                    },
                    child: Text(l10n.goBack),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedReason == null
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              CancelBookingDecision.confirmed(
                                reason: selectedReason!,
                              ),
                            );
                          },
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
