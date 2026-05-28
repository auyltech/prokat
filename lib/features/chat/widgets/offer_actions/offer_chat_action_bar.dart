import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_controller.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/widgets/counter_offer_sheet.dart';

class OfferChatActionBar extends ConsumerWidget {
  final String chatId;
  final OfferModel offer;
  final String type;

  const OfferChatActionBar({
    super.key,
    required this.chatId,
    required this.offer,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(offerChatActionControllerProvider);

    final currentUserId = ref.watch(authProvider).session?.user?.id;
    final negotiationState = ref.watch(
      priceNegotiationByOfferProvider(offer.id),
    );

    final pending = negotiationState.latestPending;
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

    final secondaryLabel = pendingId.isEmpty || pendingFromMe ? null : 'Reject';

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
              if (secondaryLabel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: negotiationState.isSubmitting
                        ? null
                        : () => controller.respond(
                            context: context,
                            chatId: chatId,
                            offerId: offer.id,
                            negotiationId: pendingId,
                            response: PriceNegotiationResponse.reject,
                          ),
                    child: Text(secondaryLabel),
                  ),
                ),
                const SizedBox(width: 12),
              ],
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
                                offerId: offer.id,
                                initialPrice: offer.price,
                                initialPriceRate: offer.priceRate,
                                counterType: type,
                              ),
                            );

                            if (created == true) {
                              await controller.refreshAfterNegotiation(
                                chatId: chatId,
                                offerId: offer.id,
                              );
                            }
                            return;
                          }

                          if (pendingFromMe) {
                            await controller.cancel(
                              context: context,
                              chatId: chatId,
                              offerId: offer.id,
                              negotiationId: pendingId,
                            );
                            return;
                          }

                          await controller.respond(
                            context: context,
                            chatId: chatId,
                            offerId: offer.id,
                            negotiationId: pendingId,
                            response: PriceNegotiationResponse.accept,
                          );
                        },
                  child: Text(primaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
