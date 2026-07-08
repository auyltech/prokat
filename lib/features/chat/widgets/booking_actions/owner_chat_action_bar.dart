import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_reason_sheet.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/booking_actions/chat_status_only_bar.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';

class OwnerChatActionBar extends ConsumerWidget {
  final String chatId;
  final ChatStatus chatStatus;
  final BookingModel booking;
  final String? chatOwnerId;
  final String? chatClientId;

  const OwnerChatActionBar({
    super.key,
    required this.chatId,
    required this.chatStatus,
    required this.booking,
    this.chatOwnerId,
    this.chatClientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final submitState = ref.watch(
      bookingChatActionControllerProvider(booking.id),
    );

    final controller = ref.read(
      bookingChatActionControllerProvider(booking.id).notifier,
    );

    final statusText = getChatActionBarTitle(chatStatus);

    if (chatStatus == ChatStatus.bookingreviewed) {
      return ChatStatusOnlyBar(text: "Review Sent");
    } else if (chatStatus == ChatStatus.bookingcancelled) {
      return ChatStatusOnlyBar(text: "Order Cancelled");
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            statusText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              // Order Created
              if (chatStatus == ChatStatus.bookingcreated) ...[
                // Accept order
                const SizedBox(width: 6),

                // Create Counter Offer
                const SizedBox(width: 6),

                // Reject Order
              ]
              // Counter Offers
              else if (chatStatus == ChatStatus.counteroffersent) ...[
                // Cancel Counter Offer
              ] else if (chatStatus == ChatStatus.counterofferreceived) ...[
                // Accept Counter Offer

                // Reject Counter Offer
              ] else if (chatStatus == ChatStatus.bookingconfirmed) ...[
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Reject Order",
                    isEnabled: !submitState.isSubmitting,
                    isLoading:
                        submitState.isSubmitting &&
                        submitState.submitId == "booking:reject",
                    onPressed: () async {
                      final decision =
                          await showModalBottomSheet<CancelBookingDecision>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: theme.colorScheme.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => CancelBookingReasonSheet(
                              booking: booking,
                              useCase: 'owner',
                            ),
                          );

                      if (!context.mounted) return;

                      if (decision == null || decision.confirmed == false) {
                        return;
                      }

                      final reason = decision.reason;

                      if (reason == null || reason.trim().isEmpty) {
                        return;
                      }

                      await controller.rejectBooking(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        reason: reason.trim(),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 6),

                // Completed Work
                Expanded(
                  child: ActionBarButton(
                    label: "Complete Work",
                    isEnabled: !submitState.isSubmitting,
                    isLoading:
                        submitState.isSubmitting &&
                        submitState.submitId == "booking:workstatus",
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.colorScheme.surface,
                          title: const Text('Mark completed?'),
                          content: const Text(
                            'Client will need to confirm completion.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context, true);

                                await ref
                                    .read(bookingMutationProvider.notifier)
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

                      if (confirmed != true) return;
                    },
                  ),
                ),

                const SizedBox(width: 6),

                // Update Work Status
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Update Status",
                    isEnabled: !submitState.isSubmitting,
                    isLoading:
                        submitState.isSubmitting &&
                        submitState.submitId == "booking:workstatus",
                    onPressed: () async {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => BookingStatusSheet(booking: booking),
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.leaveReview) ...[
                // Submit Review
                Expanded(
                  child: ActionBarButton(
                    label: "Review",
                    isEnabled: !submitState.isSubmitting,
                    isLoading:
                        submitState.isSubmitting &&
                        submitState.submitId == "review:submit",
                    onPressed: () async {
                      final submitted = await showModalBottomSheet<bool>(
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
                          revieweeId: chatClientId ?? "",
                          title: 'Review client',
                        ),
                      );

                      if (submitted == true) {
                        await controller.refreshAfterReview(
                          chatId: chatId,
                          bookingId: booking.id,
                        );
                      }
                    },
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
