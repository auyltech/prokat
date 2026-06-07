import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/show_counter_offer_sheet.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';

class OfferChatActionBar extends ConsumerWidget {
  final ChatStatus chatStatus;
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

    final activeRequestOffer = ref
        .read(offersProvider.notifier)
        .getActiveOffers(requestId, mode)
        .firstOrNull;

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
              if (chatStatus == ChatStatus.requestcreated) ...[
                if (mode == "owner")
                  // Hide request
                  Expanded(
                    child: ActionBarButton.destructive(
                      label: "Hide Request",
                      isEnabled: true,
                      isLoading: false,
                      onPressed: () async {},
                    ),
                  )
                else
                  // Cancel request
                  Expanded(
                    child: ActionBarButton.danger(
                      label: "Cancel Request",
                      isEnabled: true,
                      isLoading: false,
                      onPressed: () async {
                        await controller.cancelRequest(
                          context: context,
                          chatId: chatId,
                          requestId: requestId,
                        );
                      },
                    ),
                  ),

                const SizedBox(width: 12),

                // Create Price Negotiation
                // Create Counter Offer
                Expanded(
                  child: ActionBarButton.secondary(
                    label: "Counter",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await showCounterOfferSheet(
                        context: context,
                        chatId: chatId,
                        offerId: lastOffer?.id ?? "",
                        initialPrice: lastOffer?.price ?? 0,
                        initialPriceRate: getRateOption(lastOffer?.priceRate),
                        mode: mode,
                      );

                      await controller.refreshAfterNegotiation(
                        chatId: chatId,
                        offerId: lastOffer?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.requestaccepted) ...[
                // edge case: should have a booking
                // Cancel request
                Expanded(
                  child: ActionBarButton.danger(
                    label: "Cancel Request",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.cancelRequest(
                        context: context,
                        chatId: chatId,
                        requestId: requestId,
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.offerreceived) ...[
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Reject Offer",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.rejectRequestOffer(
                        context: context,
                        chatId: chatId,
                        offerId: activeRequestOffer?.id ?? "",
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ActionBarButton(
                    label: "Accept Offer",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.acceptRequestOffer(
                        context: context,
                        chatId: chatId,
                        offerId: activeRequestOffer?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.offercreated) ...[
                // CANCEL OFFER
                Expanded(
                  child: ActionBarButton.destructive(
                    label: "Cancel Offer",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.cancelOffer(
                        context: context,
                        chatId: chatId,
                        offerId: lastOffer?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.counterofferreceived) ...[
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
              ] else if (chatStatus == ChatStatus.counteroffersent) ...[
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
