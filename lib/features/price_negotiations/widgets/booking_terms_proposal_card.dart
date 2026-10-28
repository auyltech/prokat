import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_summary.dart';
import 'package:prokat/features/price_negotiations/widgets/price_negotiation_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BookingTermsProposalCard extends ConsumerWidget {
  final PriceNegotiation proposal;
  final bool isMe;
  final String chatId;
  const BookingTermsProposalCard({
    super.key,
    required this.proposal,
    required this.isMe,
    required this.chatId,
  });

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    PriceNegotiationResponse decision,
  ) async {
    try {
      await ref
          .read(priceNegotiationMutationProvider.notifier)
          .respondToPriceNegotiation(
            negotiationId: proposal.id,
            response: decision,
            bookingId: proposal.bookingId,
            chatId: chatId,
            acceptedTermsVersion: decision == PriceNegotiationResponse.accept
                ? proposal.proposedTerms?.version
                : null,
            expectedNegotiationUpdatedAt:
                decision == PriceNegotiationResponse.accept
                ? proposal.updatedAt
                : null,
          );
    } catch (_) {
      if (!context.mounted) return;
      AppToast.show(
        message: AppLocalizations.of(context)!.orderTermsRefreshRequired,
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final terms = proposal.proposedTerms;
    final busy = ref.watch(priceNegotiationMutationProvider).isSubmitting;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.filePenLine,
                    size: 21,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.orderTermsProposalTitle,
                      style: TextStyle(
                        color: palette.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: PriceNegotiationStatusBadge(status: proposal.status),
              ),
              const SizedBox(height: 12),
              if (terms == null)
                Text(
                  l10n.orderTermsUpdateRequired,
                  style: TextStyle(color: palette.secondary),
                )
              else ...[
                BookingTermsSummary(
                  title: l10n.currentOrderTerms,
                  price: terms.previous.price,
                  priceRate: terms.previous.priceRate,
                  bookedOn: terms.previous.bookedOn,
                  bookedAt: terms.previous.bookedAt,
                  location: terms.previous.location,
                ),
                const SizedBox(height: 10),
                BookingTermsSummary(
                  title: l10n.proposedOrderTerms,
                  price: proposal.price,
                  priceRate: proposal.priceRate,
                  bookedOn: terms.bookedOn,
                  bookedAt: terms.bookedAt,
                  location: terms.location,
                  highlighted: true,
                ),
              ],
              if (proposal.comment?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(proposal.comment!, style: TextStyle(color: palette.title)),
              ],
              if (proposal.isPending) ...[
                const SizedBox(height: 12),
                if (isMe)
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(
                                    priceNegotiationMutationProvider.notifier,
                                  )
                                  .cancelPriceNegotiation(
                                    proposal.id,
                                    bookingId: proposal.bookingId,
                                    chatId: chatId,
                                  );
                            } catch (_) {
                              if (!context.mounted) return;
                              AppToast.show(
                                message: l10n.actionFailed,
                                type: AppToastType.error,
                              );
                            }
                          },
                    icon: const Icon(LucideIcons.undo2, size: 18),
                    label: Text(
                      l10n.withdrawOrderTerms,
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: busy || !proposal.canAcknowledgeTerms
                        ? null
                        : () => _respond(
                            context,
                            ref,
                            PriceNegotiationResponse.accept,
                          ),
                    icon: const Icon(LucideIcons.check, size: 18),
                    label: Text(
                      l10n.acceptOrderTerms,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => _respond(
                            context,
                            ref,
                            PriceNegotiationResponse.reject,
                          ),
                    child: Text(l10n.reject, textAlign: TextAlign.center),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
