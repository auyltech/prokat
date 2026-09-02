import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class NegotiationMessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final bool isMe;

  const NegotiationMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  ConsumerState<NegotiationMessageBubble> createState() =>
      _NegotiationMessageBubbleState();
}

class _NegotiationMessageBubbleState
    extends ConsumerState<NegotiationMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final parsed = () {
      try {
        return PriceNegotiation.fromJson(widget.message.meta!);
      } catch (error) {
        return null;
      }
    }();

    if (parsed == null) {
      return Text(l10n.failedToLoadNegotiation);
    }

    final query = priceNegotiationQueryFor(
      bookingId: parsed.bookingId,
      offerId: parsed.offerId,
    );
    final priceNegotiationState = query == null
        ? const <PriceNegotiation>[]
        : ref.watch(priceNegotiationsProvider(query)).valueOrNull?.items ??
              const <PriceNegotiation>[];
    final mutationState = ref.watch(priceNegotiationMutationProvider);

    final priceNegotiation =
        priceNegotiationState
            .where((item) => item.id == parsed.id)
            .firstOrNull ??
        parsed;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Limits the width to a maximum of 80% of the screen width
          maxWidth: MediaQuery.sizeOf(context).width * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Status Info Header
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.balance_outlined,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.priceOffer,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const Spacer(),

                  Text(priceNegotiation.status.name),
                ],
              ),
              const SizedBox(height: 8),

              // Main Body: Price details and action buttons
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Row(
                  children: [
                    Text(
                      "${formatPrice(parsed.price)} ${getPriceRate(priceNegotiation.priceRate, l10n: l10n)}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),

                    if (priceNegotiation.status ==
                            PriceNegotiationStatus.created &&
                        widget.isMe) ...[
                      if (mutationState.isSubmitting)
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          // isEnabled: !submitState.isSubmitting,
                          // isLoading:
                          //     submitState.isSubmitting &&
                          //     submitState.submitId == "price:cancel",
                          onPressed: () async {
                            await ref
                                .read(priceNegotiationMutationProvider.notifier)
                                .cancelPriceNegotiation(
                                  priceNegotiation.id,
                                  bookingId: query?.bookingId,
                                  offerId: query?.offerId,
                                  chatId: widget.message.chatId,
                                );
                          },
                          iconSize: 32,
                          padding: const EdgeInsets.all(0),
                          icon: const Icon(Icons.clear, color: Colors.red),
                        ),
                    ] else if (priceNegotiation.status ==
                        PriceNegotiationStatus.created) ...[
                      if (ref
                          .watch(priceNegotiationMutationProvider)
                          .isActionActive("price:reject"))
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () async {
                            await ref
                                .read(priceNegotiationMutationProvider.notifier)
                                .respondToPriceNegotiation(
                                  negotiationId: priceNegotiation.id,
                                  response: PriceNegotiationResponse.reject,
                                  bookingId: query?.bookingId,
                                  offerId: query?.offerId,
                                  chatId: widget.message.chatId,
                                );

                            // chatId: widget.message.chatId,
                          },
                          iconSize: 32,
                          padding: const EdgeInsets.all(0),
                          icon: const Icon(Icons.clear, color: Colors.red),
                        ),

                      if (ref
                          .watch(priceNegotiationMutationProvider)
                          .isActionActive("price:accept"))
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () async {
                            await ref
                                .read(priceNegotiationMutationProvider.notifier)
                                .respondToPriceNegotiation(
                                  negotiationId: priceNegotiation.id,
                                  response: PriceNegotiationResponse.accept,
                                  bookingId: query?.bookingId,
                                  offerId: query?.offerId,
                                  chatId: widget.message.chatId,
                                );
                          },
                          iconSize: 32,
                          padding: const EdgeInsets.all(0),
                          icon: const Icon(Icons.check, color: Colors.green),
                        ),
                    ],
                  ],
                ),
              ),

              Text(
                formatDateTime(
                  parsed.createdAt,
                  parsed.createdAt,
                  locale: l10n.localeName,
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
