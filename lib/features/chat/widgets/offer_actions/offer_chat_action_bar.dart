import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_controller.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(offerChatActionControllerProvider);

    final offerQuery = OfferQuery(
      filter: OfferListFilter.active,
      requestId: requestId,
    );
    final offerState = mode == 'owner'
        ? ref.watch(ownerOffersProvider(offerQuery))
        : ref.watch(clientOffersProvider(offerQuery));
    final offers = offerState.valueOrNull?.items ?? const [];
    final matching = offers.where((offer) => offer.requestId == requestId);
    final lastOffer = matching.isEmpty ? null : matching.first;

    final negotiationQuery = lastOffer == null
        ? null
        : PriceNegotiationQuery(
            offerId: lastOffer.id,
            filter: PriceNegotiationListFilter.active,
          );
    final negotiations = negotiationQuery == null
        ? const <PriceNegotiation>[]
        : ref
                  .watch(priceNegotiationsProvider(negotiationQuery))
                  .valueOrNull
                  ?.items ??
              const <PriceNegotiation>[];
    PriceNegotiation? pending;
    for (final negotiation in negotiations) {
      if (negotiation.isPending) {
        pending = negotiation;
        break;
      }
    }
    final pendingId = (pending?.id ?? '').trim();

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
            "actionBarTitle",
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
                    label: l10n.rejectPrice,
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
                    label: l10n.acceptPrice,
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
                    label: l10n.cancelPrice,
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
