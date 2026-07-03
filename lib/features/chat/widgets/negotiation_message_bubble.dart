import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
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
      return Text("Failed to load negotiation");
    }

    final priceNegotiationState = ref
        .read(priceNegotiationProvider)
        .negotiations;

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
                    color: theme.primaryColor,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Price Offer",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),

                  Spacer(),

                  Text(priceNegotiation.status.name),
                ],
              ),
              const SizedBox(height: 8),

              // Main Body: Price details and action buttons
              Padding(
                padding: EdgeInsets.only(left: 0),
                child: Row(
                  children: [
                    Text(
                      "${formatPrice(parsed.price)} ${getPriceRate(priceNegotiation.priceRate, l10n: l10n)}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Spacer(),

                    if (priceNegotiation.status ==
                            PriceNegotiationStatus.created &&
                        widget.isMe) ...[
                      if (ref.watch(priceNegotiationProvider).isSubmitting)
                        SizedBox(
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
                                .read(priceNegotiationProvider.notifier)
                                .cancelPriceNegotiation(priceNegotiation.id);
                          },
                          iconSize: 32,
                          padding: EdgeInsets.all(0),
                          icon: Icon(Icons.clear, color: Colors.red),
                        ),
                    ] else if (priceNegotiation.status ==
                        PriceNegotiationStatus.created) ...[
                      if (ref.watch(priceNegotiationProvider).isSubmitting)
                        SizedBox(
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
                          //     submitState.submitId == "price:reject",
                          onPressed: () async {
                            await ref
                                .read(priceNegotiationProvider.notifier)
                                .respondToPriceNegotiation(
                                  negotiationId: priceNegotiation.id,
                                  response: PriceNegotiationResponse.reject,
                                );

                            // chatId: widget.message.chatId,
                          },
                          iconSize: 32,
                          padding: EdgeInsets.all(0),
                          icon: Icon(Icons.clear, color: Colors.red),
                        ),

                      if (ref.watch(priceNegotiationProvider).isSubmitting)
                        SizedBox(
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
                                .read(priceNegotiationProvider.notifier)
                                .respondToPriceNegotiation(
                                  negotiationId: priceNegotiation.id,
                                  response: PriceNegotiationResponse.accept,
                                );
                          },
                          iconSize: 32,
                          padding: EdgeInsets.all(0),
                          icon: Icon(Icons.check, color: Colors.green),
                        ),
                    ],
                  ],
                ),
              ),

              Text(
                formatDateTime(parsed.createdAt, parsed.createdAt),
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
