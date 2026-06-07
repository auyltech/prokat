import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
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
        return PriceNegotiation.fromJson(
          widget.message.meta?["priceNegotiation"],
        );
      } catch (error) {
        return null;
      }
    }();

    if (parsed == null) {
      return Text("Failed to load negotiation");
    }

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
            // 1. Light theme surface that mirrors the app's structural layout
            color: const Color(0xFFF4F9FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color.fromARGB(255, 197, 229, 255),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Status Info Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.balance_outlined,
                        color: theme.primaryColor,
                        size: 26,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Counter Offer",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
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
              const SizedBox(height: 8),

              // Main Body: Price details and action buttons
              Padding(
                padding: EdgeInsets.only(left: 32),
                child: Row(
                  children: [
                    Text(
                      "${formatPrice(parsed.price)} ${getPriceRate(parsed.priceRate, l10n: l10n)}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Spacer(),

                    //     IconButton(
                    //       onPressed: () {
                    //         // TODO: Implement reject logic
                    //       },
                    //       constraints: const BoxConstraints(),
                    //       padding: const EdgeInsets.all(10),
                    //       style: IconButton.styleFrom(
                    //         backgroundColor: theme.colorScheme.error.withValues(
                    //           alpha: 0.1,
                    //         ),
                    //         foregroundColor: theme.colorScheme.error,
                    //         shape: const CircleBorder(),
                    //       ),
                    //       icon: const Icon(Icons.close_rounded, size: 20),
                    //     ),

                    //     IconButton(
                    //       onPressed: () {
                    //         // TODO: Implement accept logic
                    //       },
                    //       constraints: const BoxConstraints(),
                    //       padding: const EdgeInsets.all(10),
                    //       style: IconButton.styleFrom(
                    //         backgroundColor: theme.primaryColor,
                    //         foregroundColor: Colors.white,
                    //         shape: const CircleBorder(),
                    //         shadowColor: theme.primaryColor.withValues(
                    //           alpha: 0.3,
                    //         ),
                    //         elevation: 2,
                    //       ),
                    //       icon: const Icon(Icons.check_rounded, size: 20),
                    //     ),
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
