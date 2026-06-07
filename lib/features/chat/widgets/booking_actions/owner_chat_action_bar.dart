import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_reason_sheet.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/booking_actions/chat_status_only_bar.dart';
import 'package:prokat/features/chat/widgets/show_counter_offer_sheet.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
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

    final negotiationNotifier = ref.watch(priceNegotiationProvider.notifier);
    final pending = negotiationNotifier.getPendingNegotiation(
      bookingId: booking.id,
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
                Expanded(
                  child: ActionBarButton(
                    label: "Accept Order",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: theme.colorScheme.surface,
                          title: const Text('Accept order?'),
                          content: const Text(
                            'Confirm accepting this booking.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),

                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context, true);

                                await controller.acceptBooking(
                                  context: context,
                                  chatId: chatId,
                                  bookingId: booking.id,
                                );
                              },
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 6),

                // Create Counter Offer
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Counter",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      await showCounterOfferSheet(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        initialPrice: booking.price,
                        initialPriceRate: getRateOption(booking.priceRate),
                        mode: "owner",
                      );
                    },
                  ),
                ),

                const SizedBox(width: 6),

                // Reject Order
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Reject Order",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
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
              ]
              // Counter Offers
              else if (chatStatus == ChatStatus.counteroffersent) ...[
                // Cancel Counter Offer
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Cancel Offer",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      await controller.cancelNegotiation(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        negotiationId: pending?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.counterofferreceived) ...[
                // Accept Counter Offer
                Expanded(
                  child: ActionBarButton(
                    label: "Accept Offer",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      await controller.acceptCounterOffer(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        negotiationId: pending?.id ?? "",
                      );
                    },
                  ),
                ),

                const SizedBox(width: 6),

                // Reject Counter Offer
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Reject Offer",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      await controller.rejectCounterOffer(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        negotiationId: pending?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.bookingconfirmed) ...[
                // Completed Work
                Expanded(
                  child: ActionBarButton(
                    label: "Complete Work",
                    isEnabled: !submitState.isSubmitting,
                    isLoading: submitState.isSubmitting,
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

                                await controller.markWorkCompleted(
                                  context: context,
                                  chatId: chatId,
                                  bookingId: booking.id,
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
                    isLoading: submitState.isSubmitting,
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
                    isLoading: submitState.isSubmitting,
                    onPressed: () async {
                      // final revieweeId = (action.payloadId ?? '').trim();
                      // if (revieweeId.isEmpty) return;

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
