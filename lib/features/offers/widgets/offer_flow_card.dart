import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/offer_price_selection.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// The offer view has no mutations: its parent supplies the existing actions.
class OfferFlowCard extends StatelessWidget {
  final OfferModel offer;
  final Widget avatar;
  final bool isBestPrice;
  final bool submitting;
  final int unreadCount;
  final VoidCallback? onChat;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OfferFlowCard({
    super.key,
    required this.offer,
    required this.avatar,
    this.isBestPrice = false,
    this.submitting = false,
    this.unreadCount = 0,
    this.onChat,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final owner = offer.owner;
    final rating = owner?.rating;
    final hasRating =
        rating != null && rating.isFinite && rating > 0 && rating <= 5;
    final pending = OfferPriceSelection.isPending(offer);
    final comment = offer.comment?.trim() ?? '';
    final equipment = offer.equipment;
    final equipmentLabel = [equipment?.name, equipment?.model]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isBestPrice ? palette.primary : palette.border,
          width: isBestPrice ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner?.displayNameOr(l10n.nameNotSpecified) ??
                          l10n.nameNotSpecified,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.title,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          if (hasRating) ...[
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF5B736),
                                size: 16,
                              ),
                            ),
                            TextSpan(text: ' ${rating.toStringAsFixed(1)}'),
                          ] else
                            TextSpan(text: l10n.listingNoReviews),
                          if (owner?.orderCount != null)
                            TextSpan(
                              text:
                                  ' · ${l10n.ordersCount(owner!.orderCount!)}',
                            ),
                        ],
                      ),
                      style: TextStyle(color: palette.secondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                offer.price > 0
                    ? formatPrice(offer.price)
                    : l10n.priceNotSpecified,
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (offer.priceRate != null)
                Text(
                  getPriceRate(offer.priceRate, l10n: l10n),
                  style: TextStyle(color: palette.secondary, fontSize: 14),
                ),
              if (isBestPrice)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primarySoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    l10n.offerBestPrice,
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (equipmentLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              equipmentLabel,
              style: TextStyle(color: palette.title, fontSize: 14),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(color: palette.secondary, fontSize: 14),
            ),
          ],
          if (!pending) ...[
            const SizedBox(height: 10),
            Text(
              getOfferStatus(offer.status, l10n: l10n),
              style: TextStyle(color: palette.secondary, fontSize: 12),
            ),
          ],
          if (onChat != null || pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (onChat != null) ...[
                  Badge(
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: palette.filledPrimary,
                    label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                    child: ProkatFlowIconButton(
                      icon: LucideIcons.messageCircle,
                      label: l10n.chatSection,
                      onPressed: onChat,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (pending)
                  Expanded(
                    child: ProkatFlowPrimaryButton(
                      title: l10n.accept,
                      loading: submitting,
                      onPressed: submitting ? null : onAccept,
                    ),
                  ),
              ],
            ),
          ],
          if (pending)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: submitting ? null : onReject,
                style: TextButton.styleFrom(foregroundColor: palette.secondary),
                child: Text(l10n.reject),
              ),
            ),
        ],
      ),
    );
  }
}
