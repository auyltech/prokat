import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OfferMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;

  const OfferMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final offer = switch (message.meta) {
      Map<String, dynamic> meta => OfferModel.fromJson(meta["offer"]),
      _ => null,
    };

    if (offer == null) return const SizedBox.shrink();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: Colors.brown,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(message.content, style: theme.textTheme.bodyMedium),
                ],
              ),

              Padding(
                padding: EdgeInsets.only(left: 32),
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
                    // IconButton(
                    //   onPressed: () {},
                    //   iconSize: 32,
                    //   padding: EdgeInsets.all(0),
                    //   icon: Icon(Icons.check, color: Colors.green),
                    // ),
                    // IconButton(
                    //   onPressed: () {},
                    //   iconSize: 32,
                    //   padding: EdgeInsets.all(0),
                    //   icon: Icon(Icons.clear, color: Colors.red),
                    // ),
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
