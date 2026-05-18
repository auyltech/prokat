import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/widgets/cancel_booking_sheet.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_models.dart';
import 'package:prokat/features/chat/widgets/booking_actions/booking_chat_action_resolver.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/features/reviews/widgets/review_sheet.dart';

class ClientChatActionBar extends ConsumerWidget {
  final String chatId;
  final BookingModel booking;
  final String? chatOwnerId;
  final String? chatClientId;

  const ClientChatActionBar({
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
    final negotiation = ref.watch(priceNegotiationByBookingProvider(booking.id));
    final reviewState = ref.watch(reviewByBookingProvider(booking.id));
    const resolver = BookingChatActionResolver();

    final resolution = resolver.resolve(
      booking: booking,
      role: BookingChatRole.client,
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

    final primary = resolution.primaryAction;
    final secondary = resolution.secondaryActions;
    final overflow = resolution.overflowActions;

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
            resolution.statusText,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (secondary.isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    onPressed: secondary.first.isEnabled
                        ? () => _runAction(
                            context: context,
                            controller: controller,
                            action: secondary.first,
                          )
                        : null,
                    child: Text(secondary.first.label),
                  ),
                ),
              if (secondary.isNotEmpty && primary != null)
                const SizedBox(width: 12),
              if (overflow.isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    onPressed: overflow.first.isEnabled
                        ? () => _runAction(
                            context: context,
                            controller: controller,
                            action: overflow.first,
                          )
                        : null,
                    child: Text(overflow.first.label),
                  ),
                ),
              if ((secondary.isNotEmpty || overflow.isNotEmpty) && primary != null)
                const SizedBox(width: 12),
              if (primary != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: primary.isEnabled
                        ? () => _runAction(
                            context: context,
                            controller: controller,
                            action: primary,
                          )
                        : null,
                    child: Text(primary.label),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runAction({
    required BuildContext context,
    required BookingChatActionController controller,
    required BookingChatActionVm action,
  }) async {
    final theme = Theme.of(context);

    switch (action.id) {
      case BookingChatActionId.cancelBooking:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) =>
              CancelBookingSheet(booking: booking, useCase: 'client'),
        );
        return;

      case BookingChatActionId.createCounterOffer:
        final created = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => CounterOfferSheet(
            bookingId: booking.id,
            initialPrice: booking.price,
            initialPriceRate: booking.priceRate,
            counterType: "CLIENT_COUNTER",
          ),
        );
        if (created == true) {
          await controller.refreshAfterNegotiation(chatId: chatId, bookingId: booking.id);
        }
        return;
        
      case BookingChatActionId.confirmCompletion:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            title: const Text('Confirm completion?'),
            content: const Text('Confirm the work is completed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not yet'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await controller.runAction(
          context: context,
          chatId: chatId,
          bookingId: booking.id,
          actionId: action.id,
          payloadId: action.payloadId,
        );
        return;

      case BookingChatActionId.leaveReview:
        final revieweeId = (action.payloadId ?? '').trim();
        if (revieweeId.isEmpty) return;

        final submitted = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => ReviewSheet(
            bookingId: booking.id,
            revieweeId: revieweeId,
            title: 'Review owner',
          ),
        );

        if (submitted == true) {
          await controller.refreshAfterReview(chatId: chatId, bookingId: booking.id);
        }
        return;

      case BookingChatActionId.acceptCounterOffer:
      case BookingChatActionId.rejectCounterOffer:
      case BookingChatActionId.cancelCounterOffer:
        await controller.runAction(
          context: context,
          chatId: chatId,
          bookingId: booking.id,
          actionId: action.id,
          payloadId: action.payloadId,
        );
        return;
      default:
        return;
    }
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
