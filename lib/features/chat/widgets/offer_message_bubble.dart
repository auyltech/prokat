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
      Map<String, dynamic> meta => OfferModel.fromJson(meta),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'OFFER',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              Text(
                "${formatPrice(offer.price)} ${getPriceRate(offer.priceRate, l10n: l10n)}",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF0D47A1),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
