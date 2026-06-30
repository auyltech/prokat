import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OfferMessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final bool isMe;

  const OfferMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
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
      Map<String, dynamic> meta => OfferModel.fromJson(meta["offer"]),
      _ => null,
    };

    if (parsed == null) return const SizedBox.shrink();

    final offers = [
      ...ref.watch(offersProvider).renterOffers,
      ...ref.read(offersProvider).ownerOffers,
    ];

    final offer = offers.where((item) => item.id == parsed.id).firstOrNull;

    if (offer == null) return const SizedBox.shrink();

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
                  Icon(
                    Icons.local_offer_outlined,
                    color: Colors.brown,
                    size: 26,
                  ),
                  const SizedBox(width: 8),

                  Text("Offer", style: theme.textTheme.bodyMedium),

                  Spacer(),

                  Text(offer.status.name),
                ],
              ),

              SizedBox(height: 4),

              if (offer.equipment != null)
                EquipmentInfoTile(equipment: offer.equipment),

              SizedBox(height: 8),

              Padding(
                padding: EdgeInsets.only(left: 0),
                child: Row(
                  children: [
                    Text(
                      "${formatPrice(offer.price)} ${getPriceRate(offer.priceRate, l10n: l10n)}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    Spacer(),

                    if (offer.status == OfferStatus.created && widget.isMe) ...[
                      // Cancel Offer
                      IconButton(
                        onPressed: () async {
                          await ref
                              .read(offersProvider.notifier)
                              .cancelOffer(
                                offer.id,
                                chatId: widget.message.chatId,
                              );
                        },
                        iconSize: 32,
                        padding: EdgeInsets.all(0),
                        icon: Icon(Icons.clear, color: Colors.red),
                      ),
                    ] else if (offer.status == OfferStatus.created) ...[
                      // Reject Offer
                      IconButton(
                        onPressed: () async {
                          await ref
                              .read(offersProvider.notifier)
                              .rejectOffer(
                                offer.id,
                                chatId: widget.message.chatId,
                              );
                        },
                        iconSize: 32,
                        padding: EdgeInsets.all(0),
                        icon: Icon(Icons.clear, color: Colors.red),
                      ),

                      // Accept Offer
                      IconButton(
                        onPressed: () async {
                          await ref
                              .read(offersProvider.notifier)
                              .acceptOffer(
                                offer.id,
                                chatId: widget.message.chatId,
                              );
                        },
                        iconSize: 32,
                        padding: EdgeInsets.all(0),
                        icon: Icon(Icons.check, color: Colors.green),
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
