import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/widgets/booking_status_sheet.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_resolver.dart';
import 'package:prokat/features/chat/widgets/show_counter_offer_sheet.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';

ChatStatus getChatStatus({
  required String bookingStatus,
  required WorkStatus workStatus,
  bool hasNegotiation = false,
  bool pendingFromMe = false,
}) {
  // 1. Handle Created Status with Negotiation Logic
  if (bookingStatus == "CREATED") {
    if (hasNegotiation) {
      if (pendingFromMe) {
        return ChatStatus.counterofferreceived;
      } else {
        return ChatStatus.counteroffersent;
      }
    }

    return ChatStatus.bookingcreated;
  }

  // 2. Handle Finalized Booking Statuses
  if (bookingStatus == "CONFIRMED") {
    if (workStatus == WorkStatus.completed) return ChatStatus.workcompleted;

    return ChatStatus.bookingconfirmed;
  }

  if (bookingStatus == "REVIEWED") {
    return ChatStatus.bookingreviewed;
  }

  // 3. Fallback Default Status
  return ChatStatus.bookingcompleted;
}

class OwnerChatActionBar extends ConsumerWidget {
  final String chatId;
  final BookingModel booking;
  final String? chatOwnerId;
  final String? chatClientId;

  const OwnerChatActionBar({
    super.key,
    required this.chatId,
    required this.booking,
    this.chatOwnerId,
    this.chatClientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(bookingChatActionControllerProvider);
    final currentUserId = ref.watch(authProvider).session?.user?.id;
    final negotiation = ref.watch(
      priceNegotiationByBookingProvider(booking.id),
    );

    final reviewState = ref.watch(reviewByBookingProvider(booking.id));

    final pending = negotiation.latestPending;
    final pendingId = (pending?.id ?? '').trim();

    final userId = (currentUserId ?? '').trim();

    final hasNegotiation = pendingId.isNotEmpty;
    final pendingFromMe =
        pendingId.isNotEmpty &&
        userId.isNotEmpty &&
        (pending?.senderId ?? '').trim() == userId;

    final ChatStatus chat_state = getChatStatus(
      bookingStatus: booking.status,
      hasNegotiation: pendingId.isNotEmpty,
      pendingFromMe:
          pendingId.isNotEmpty &&
          userId.isNotEmpty &&
          (pending?.senderId ?? '').trim() != userId,
      workStatus: booking.workStatus,
    );

    final statusText = booking.status == "CREATED"
        ? hasNegotiation
              ? pendingFromMe
                    ? "Respond to Counter Offer"
                    : "Counter Offer Sent"
              : "New Booking"
        : "";

    const resolver = BookingChatActionResolver();

    final resolution = resolver.resolve(
      booking: booking,
      role: BookingChatRole.owner,
      now: DateTime.now(),
      negotiation: negotiation,
      reviewState: reviewState,
      currentUserId: currentUserId,
      chatOwnerId: chatOwnerId,
      chatClientId: chatClientId,
    );

    if (resolution.primaryAction == null &&
        resolution.secondaryActions.isEmpty &&
        resolution.overflowActions.isEmpty) {
      return _StatusOnlyBar(text: resolution.statusText);
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
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              // Order Created
              // Counter Offers
              if (chat_state == ChatStatus.counteroffersent) ...[
                Expanded(
                  child: ActionBarButton(
                    label: "Cancel Offer",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.cancelNegotiation(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        negotiationId: negotiation.latestPending?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chat_state == ChatStatus.counterofferreceived) ...[
                Expanded(
                  child: ActionBarButton(
                    label: "Accept Offer",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.acceptCounterOffer(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        negotiationId: negotiation.latestPending?.id ?? "",
                      );
                    },
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Reject Offer",
                    isEnabled: true,
                    isLoading:
                        false, // Automatically disables interaction if true
                    onPressed: () async {
                      await controller.rejectCounterOffer(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        negotiationId: negotiation.latestPending?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chat_state == ChatStatus.bookingcreated) ...[
                Expanded(
                  child: ActionBarButton(
                    label: "Accept Order",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
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
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Accept'),
                            ),
                          ],
                        ),
                      );

                      // await controller.acceptBooking(
                      //   context: context,
                      //   chatId: chatId,
                      //   bookingId: booking.id,
                      // );
                    },
                  ),
                ),
                SizedBox(width: 2),
                // Send Counter Offer
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Counter",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await showCounterOfferSheet(
                        context: context,
                        chatId: chatId,
                        bookingId: booking.id,
                        initialPrice: booking.price,
                        initialPriceRate: getRateOption(booking.priceRate),
                        counterType: "OWNER_COUNTER",
                      );
                    },
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Reject Order",
                    isEnabled: true,
                    isLoading: false,
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
                        builder: (_) => CancelBookingSheet(
                          booking: booking,
                          useCase: 'owner',
                        ),
                      );

                      // await controller.rejectBooking(
                      //   context: context,
                      //   chatId: chatId,
                      //   bookingId: booking.id,
                      //   reason: "reason",
                      // );
                    },
                  ),
                ),
              ] else if (chat_state == ChatStatus.bookingconfirmed) ...[
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Complete Work",
                    isEnabled: true,
                    isLoading: false,
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
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Mark completed'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;
                    },
                  ),
                ),
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Update Status",
                    isEnabled: true,
                    isLoading: false,
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
              ] else if (chat_state == ChatStatus.bookingcompleted) ...[
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Review",
                    isEnabled: true,
                    isLoading: false,
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
                          revieweeId: "revieweeId",
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
              ] else
                SizedBox(),

              // if (overflow.isNotEmpty)
              //   Expanded(
              //     child: OutlinedButton(
              //       onPressed: overflow.first.isEnabled
              //           ? () => _runAction(
              //               context: context,
              //               ref: ref,
              //               controller: controller,
              //               action: overflow.first,
              //             )
              //           : null,
              //       child: Text(overflow.first.label),
              //     ),
              //   ),

              // if (overflow.isNotEmpty && primary != null)
              //   const SizedBox(width: 12),

              // if (secondary.isNotEmpty)
              //   Expanded(
              //     child: OutlinedButton(
              //       onPressed: secondary.first.isEnabled
              //           ? () => _runAction(
              //               context: context,
              //               ref: ref,
              //               controller: controller,
              //               action: secondary.first,
              //             )
              //           : null,
              //       child: Text(secondary.first.label),
              //     ),
              //   ),

              // if (secondary.isNotEmpty && primary != null)
              //   const SizedBox(width: 12),

              // if (primary != null)
              //   Expanded(
              //     child: ElevatedButton(
              //       onPressed: primary.isEnabled
              //           ? () => _runAction(
              //               context: context,
              //               ref: ref,
              //               controller: controller,
              //               action: primary,
              //             )
              //           : null,
              //       child: Text(primary.label),
              //     ),
              //   ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusOnlyBar extends StatelessWidget {
  final String text;

  const _StatusOnlyBar({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
