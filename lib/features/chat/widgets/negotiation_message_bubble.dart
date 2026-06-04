import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/chat/state/chat_message_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class NegotiationMessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;

  const NegotiationMessageBubble({super.key, required this.message});

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

    final parsed = PriceNegotiation.fromJson(
      widget.message.meta?["priceNegotiation"],
    );

    // final priceNegotiation = ref
    //     .read(priceNegotiationProvider)
    //     .negotiations
    //     .where((item) => item.id == ["id"])
    //     .firstOrNull;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // 1. Light theme surface that mirrors the app's structural layout
        color: theme.colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                    Icons.gavel_rounded,
                    size: 14,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "COUNTER OFFER",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme
                          .primaryColor, // Matches page header branding color
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
          const SizedBox(height: 12),

          // Main Body: Price details and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price presentation on the left
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "\$${parsed.price}", // Added currency symbol to match top header card style
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (parsed.priceRate != null) ...[
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "/ ${parsed.priceRate!.toLowerCase()}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.outline,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons on the right
              Row(
                children: [
                  // Decline Button (Clean subtle layout)
                  IconButton(
                    onPressed: () {
                      // TODO: Implement reject logic
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.error.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: theme.colorScheme.error,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                  const SizedBox(width: 10),

                  // Accept Button (Uses primary blue theme setup)
                  IconButton(
                    onPressed: () {
                      // TODO: Implement accept logic
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      shadowColor: theme.primaryColor.withValues(alpha: 0.3),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
