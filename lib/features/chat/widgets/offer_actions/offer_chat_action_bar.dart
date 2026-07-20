import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_controller.dart';
import 'package:prokat/features/chat/widgets/show_counter_offer_sheet.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
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
              if (chatStatus == ChatStatusDetail.requestcreated) ...[
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
                        final result = await ref
                            .read(requestMutationProvider.notifier)
                            .cancelRequest(requestId);

                        AppSnackBar.show(
                          message: result.success
                              ? l10n.requestCancelled
                              : "Failed to cancel request",
                          isSuccess: result.success,
                          isError: !result.success,
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
                        offerId: lastOffer?.id,
                        initialPrice: lastOffer?.price ?? 0,
                        initialPriceRate: (lastOffer?.priceRate)!,
                        mode: mode,
                      );

                      await controller.refreshAfterNegotiation(
                        chatId: chatId,
                        offerId: lastOffer?.id ?? "",
                      );
                    },
                  ),
                ),
              ] else if (chatStatus == ChatStatusDetail.requestaccepted) ...[
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
              ] else if (chatStatus == ChatStatusDetail.offerreceived)
                ...[
              ] else if (chatStatus == ChatStatusDetail.offercreated) ...[
                // CANCEL OFFER
              ] else if (chatStatus ==
                  ChatStatusDetail.counterofferreceived) ...[
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
