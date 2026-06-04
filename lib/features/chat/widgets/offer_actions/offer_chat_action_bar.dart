import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_controller.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';

class OfferChatActionBar extends ConsumerWidget {
  final ChatStatus chatStatus;
  final String chatId;
  final String requestId;
  final String type;

  const OfferChatActionBar({
    super.key,
    required this.chatStatus,
    required this.chatId,
    required this.requestId,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(offerChatActionControllerProvider);

    final currentUserId = ref.watch(authProvider).session?.user?.id;

    final activeRequestOffer = ref
        .read(offersProvider.notifier)
        .getActiveOffers(requestId, "client")
        .firstOrNull;

    final lastOfferId = ref
        .read(offersProvider.notifier)
        .getLastRequestOfferId(requestId, "client");

    final hasActiveOffer = ref
        .read(offersProvider.notifier)
        .hasActiveOffer(requestId, "client");

    final negotiationState = ref.watch(priceNegotiationProvider);
    final pending = negotiationState.latestPending;

    final hasPriceNegotiation = pending != null;

    final pendingId = (pending?.id ?? '').trim();
    final userId = (currentUserId ?? '').trim();
    final pendingFromMe =
        pendingId.isNotEmpty &&
        userId.isNotEmpty &&
        (pending?.senderId ?? '').trim() == userId;

    final statusText = pendingId.isEmpty
        ? 'Offer price negotiation'
        : pendingFromMe
        ? 'Waiting for response'
        : 'New counter offer';

    final primaryLabel = pendingId.isEmpty
        ? 'Counter offer'
        : pendingFromMe
        ? 'Cancel counter'
        : 'Accept';

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
              SizedBox(width: 4),
              if (chatStatus == ChatStatus.offerreceived) ...[
                Expanded(
                  child: ActionBarButton(
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
              ] else if (chatStatus == ChatStatus.counterofferreceived) ...[
                // Reject Price Negotiation
                Expanded(
                  child: ActionBarButton(
                    label: "Reject Price",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.respond(
                        context: context,
                        chatId: chatId,
                        offerId: activeRequestOffer?.id ?? "",
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
                        offerId: activeRequestOffer?.id ?? "",
                        negotiationId: pendingId,
                        response: PriceNegotiationResponse.accept,
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatus.counteroffersent) ...[
                // Cancel Price Negotiation
                Expanded(
                  child: ActionBarButton(
                    label: "Cancel Price",
                    isEnabled: true,
                    isLoading: false,
                    onPressed: () async {
                      await controller.cancel(
                        context: context,
                        chatId: chatId,
                        offerId: activeRequestOffer?.id ?? "",
                        negotiationId: pendingId,
                      );
                    },
                  ),
                ),
              ] else ...[
                // Cancel request
                Expanded(
                  child: ActionBarButton(
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
                Expanded(
                  child: ElevatedButton(
                    onPressed: negotiationState.isSubmitting
                        ? null
                        : () async {
                            if (pendingId.isEmpty) {
                              final created = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: theme.colorScheme.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (_) => CounterOfferSheet(
                                  offerId: lastOfferId ?? "",
                                  initialPrice: activeRequestOffer?.price ?? 0,
                                  initialPriceRate:
                                      activeRequestOffer?.priceRate,
                                  counterType: type,
                                ),
                              );

                              if (created == true) {
                                await controller.refreshAfterNegotiation(
                                  chatId: chatId,
                                  offerId: activeRequestOffer?.id ?? "",
                                );
                              }
                              return;
                            }
                          },
                    child: Text(primaryLabel),
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
