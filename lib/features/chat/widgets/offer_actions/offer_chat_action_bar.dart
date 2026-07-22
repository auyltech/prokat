import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_controller.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

class OfferChatActionBar extends ConsumerWidget {
  final ChatStatusDetail chatStatus;
  final String chatId;
  final String requestId;
  final String mode;

  const OfferChatActionBar({
    super.key,
    required this.chatStatus,
    required this.chatId,
    required this.requestId,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(offerChatActionControllerProvider);

    final lastOffer = ref
        .read(offersProvider.notifier)
        .getLastRequestOffer(requestId, mode);

    final negotiationState = ref.watch(priceNegotiationProvider);
    final pending = negotiationState.latestPending;
    final pendingId = (pending?.id ?? '').trim();

    final actionBarTitle = getChatActionBarTitle(chatStatus);

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
            actionBarTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (chatStatus == ChatStatusDetail.counterofferreceived) ...[
                // Reject Price Negotiation
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Reject Price",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.respond(
                        context: context,
                        chatId: chatId,
                        offerId: lastOffer?.id ?? "",
                        negotiationId: pendingId,
                        response: PriceNegotiationResponse.reject,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Accept Price Negotiation
                Expanded(
                  child: ActionBarButton(
                    label: "Accept Price",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.respond(
                        context: context,
                        chatId: chatId,
                        offerId: lastOffer?.id ?? "",
                        negotiationId: pendingId,
                        response: PriceNegotiationResponse.accept,
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatusDetail.counteroffersent) ...[
                // Cancel Price Negotiation
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Cancel Price",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.cancel(
                        context: context,
                        chatId: chatId,
                        offerId: lastOffer?.id ?? "",
                        negotiationId: pendingId,
                      );
                    },
                  ),
                ),
              ] else
                ...[],
            ],
          ),
        ],
      ),
    );
  }
}
