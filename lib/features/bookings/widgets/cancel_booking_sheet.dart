import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';

class CancelBookingSheet extends ConsumerStatefulWidget {
  final BookingModel booking;
  final String? useCase;

  const CancelBookingSheet({super.key, required this.booking, this.useCase});

  @override
  ConsumerState<CancelBookingSheet> createState() => CancelBookingSheetState();
}

class CancelBookingSheetState extends ConsumerState<CancelBookingSheet> {
  String? selectedReason;

  final ownerCancelReasons = [
    "Client did not respond",
    "Equipment unavailable",
    "Pricing issue",
    "Scheduling conflict",
    "Other",
  ];

  final clientCancelReasons = [
    "Did not show up",
    "Changed my mind",
    "Equipment not suitable",
    "Other",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(bookingProvider.notifier);

    final sheetTitle = widget.useCase == "owner"
        ? widget.booking.status.toUpperCase() == "CREATED"
              ? "Reject Order"
              : "Cancel Order"
        : widget.useCase == "client"
        ? ""
        : "";

    final reasons = widget.useCase == "owner"
        ? ownerCancelReasons
        : clientCancelReasons;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
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

          // Confirm button
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Go Back"),
                ),
              ),
              const SizedBox(width: 12), // Space between buttons
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          final res = await notifier.updateBookingStatus(
                            id: widget.booking.id,
                            status:
                                widget.booking.status.toUpperCase() == "CREATED"
                                ? BookingStatus.rejected.name
                                : BookingStatus.failed.name,
                            workStatus: selectedReason,
                          );

                          if (res == true && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Order Cancelled")),
                            );
                          }
                        },
                  child: Text(
                    widget.booking.status.toUpperCase() == "CREATED"
                        ? "Reject Order"
                        : "Cancel Order",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
