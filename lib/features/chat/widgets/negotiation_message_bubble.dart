import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_page.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/widgets/price_negotiation_status_badge.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_proposal_card.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';

class NegotiationMessageBubble extends ConsumerStatefulWidget {
  final ChatMessageModel message;
  final bool isMe;
  final AppMode mode;

  const NegotiationMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.mode = AppMode.clientMode,
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

    // A decision event records the outcome. Keep the full comparison on the
    // original proposal message, whose actions follow the canonical row.
    if (parsed.requiresTermsAcknowledgement &&
        const {
          PriceNegotiationStatus.accepted,
          PriceNegotiationStatus.rejected,
          PriceNegotiationStatus.cancelled,
          PriceNegotiationStatus.closed,
          PriceNegotiationStatus.expired,
        }.contains(parsed.status)) {
      final palette = ProkatFlowPalette.of(context);
      final accepted = parsed.status == PriceNegotiationStatus.accepted;
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            key: const ValueKey('terms-decision-event'),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: accepted
                  ? palette.success.withValues(alpha: .08)
                  : palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Icon(
                  accepted ? LucideIcons.check : LucideIcons.undo2,
                  size: 18,
                  color: accepted ? palette.success : palette.secondary,
                ),
                Text(
                  l10n.orderTermsProposalTitle,
                  style: AppFonts.captionMedium(context)
                      .copyWith(color: palette.secondary),
                ),
                PriceNegotiationStatusBadge(status: parsed.status),
              ],
            ),
          ),
        ),
      );
    }

    final subject = priceNegotiationQueryFor(
      bookingId: parsed.bookingId,
      offerId: parsed.offerId,
    );
    final query = subject == null
        ? null
        : PriceNegotiationQuery(
            bookingId: subject.bookingId,
            offerId: subject.offerId,
          );
    final priceNegotiationState = query == null
        ? const <PriceNegotiation>[]
        : ref.watch(priceNegotiationsProvider(query)).valueOrNull?.items ??
              const <PriceNegotiation>[];
    final mutationState = ref.watch(priceNegotiationMutationProvider);

    final priceNegotiation = resolveMessageNegotiation(
      widget.message.meta!,
      priceNegotiationState,
    );

    if (priceNegotiation.requiresTermsAcknowledgement) {
      return BookingTermsProposalCard(
        proposal: priceNegotiation,
        isMe: widget.isMe,
        chatId: widget.message.chatId,
        mode: widget.mode,
      );
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.filePenLine,
                    color: theme.colorScheme.onSurface,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.priceOffer,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriceNegotiationStatusBadge(status: priceNegotiation.status),
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
                        color: theme.colorScheme.onSurface,
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
                        AppIconButton(
                          icon: Icons.clear,
                          tone: AppIconButtonTone.destructive,
                          // isEnabled: !submitState.isSubmitting,
                          // isLoading:
                          //     submitState.isSubmitting &&
                          //     submitState.submitId == "price:cancel",
                          onTap: () async {
                            await ref
                                .read(priceNegotiationMutationProvider.notifier)
                                .cancelPriceNegotiation(
                                  priceNegotiation.id,
                                  bookingId: query?.bookingId,
                                  offerId: query?.offerId,
                                  chatId: widget.message.chatId,
                                );
                          },
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
                        AppIconButton(
                          icon: Icons.clear,
                          tone: AppIconButtonTone.destructive,
                          onTap: () async {
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
                        AppIconButton(
                          icon: Icons.check,
                          tone: AppIconButtonTone.success,
                          onTap: () async {
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
