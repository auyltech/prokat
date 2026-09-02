import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/widgets/offer_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OfferMessageBubble extends ConsumerStatefulWidget {
  final ChatModel? currentChat;
  final ChatMessageModel message;
  final bool isMe;
  final AppMode mode;

  const OfferMessageBubble({
    super.key,
    this.currentChat,
    required this.message,
    required this.isMe,
    required this.mode,
  });

  @override
  ConsumerState<OfferMessageBubble> createState() => _OfferMessageBubbleState();
}

class _OfferMessageBubbleState extends ConsumerState<OfferMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final parsed = switch (widget.message.meta) {
      Map<String, dynamic> meta => OfferModel.fromJson(meta),
      _ => null,
    };

    if (parsed == null) {
      return Text(l10n.errorLoadingOffer);
    }

    final offers = widget.currentChat?.offers ?? [];
    final offer = offers.where((item) => item.id == parsed.id).firstOrNull;

    if (offer == null) {
      return Text(l10n.offerCount(offers.length));
    }

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Limits the width to a maximum of 80% of the screen width
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
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
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    color: Colors.brown,
                    size: 26,
                  ),
                  const SizedBox(width: 8),

                  Text(l10n.offer, style: theme.textTheme.bodyMedium),

                  const Spacer(),

                  OfferStatusBadge(status: offer.status),
                ],
              ),

              const SizedBox(height: 8),

              if (offer.equipment != null)
                EquipmentInfoTile(equipment: offer.equipment),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Row(
                  children: [
                    Text(
                      "${formatPrice(offer.price)} ${getPriceRate(offer.priceRate, l10n: l10n)}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const Spacer(),

                    if (offer.status == OfferStatus.created && widget.isMe) ...[
                      // Cancel Offer
                      if (ref
                          .watch(offerMutationProvider)
                          .isActionActive("offer:cancel:${offer.id}"))
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
                                .read(offerMutationProvider.notifier)
                                .cancelOffer(
                                  offer.id,
                                  chatId: widget.message.chatId,
                                  requestId: offer.requestId,
                                );
                          },
                          iconSize: 32,
                          padding: const EdgeInsets.all(0),
                          icon: const Icon(Icons.clear, color: Colors.red),
                        ),
                    ] else if (offer.status == OfferStatus.created) ...[
                      // Reject Offer
                      if (ref
                          .watch(offerMutationProvider)
                          .isActionActive("offer:reject:${offer.id}"))
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
                                .read(offerMutationProvider.notifier)
                                .rejectOffer(
                                  offer.id,
                                  chatId: widget.message.chatId,
                                  requestId: offer.requestId,
                                );
                          },
                          iconSize: 32,
                          padding: const EdgeInsets.all(0),
                          icon: const Icon(Icons.clear, color: Colors.red),
                        ),

                      // Accept Offer
                      if (ref
                          .watch(offerMutationProvider)
                          .isActionActive("offer:accept:${offer.id}"))
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () async {
                            await ref
                                .read(offerMutationProvider.notifier)
                                .acceptOffer(
                                  offer.id,
                                  chatId: widget.message.chatId,
                                  requestId: offer.requestId,
                                );
                          },
                          iconSize: 32,
                          padding: const EdgeInsets.all(0),
                          icon: const Icon(Icons.check, color: Colors.green),
                          // isEnabled: !submitState.isSubmitting,
                          // isLoading:
                          //     submitState.isSubmitting &&
                          //     submitState.submitId == "price:accept",
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
