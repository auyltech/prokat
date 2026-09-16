import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_icon_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/widgets/offer_status_badge.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/layout/reveal_client_orders_after_tender_accept.dart';

class OfferTile extends ConsumerWidget {
  final OfferModel offer;

  const OfferTile({super.key, required this.offer});

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (ref.read(offerMutationProvider).isSubmitting) {
      return;
    }

    final notifier = ref.read(offerMutationProvider.notifier);
    final navigation = TenderAcceptNavigation.capture(context);

    final result = await notifier.acceptOffer(
      offer.id,
      chatId: offer.chatId,
      requestId: offer.requestId,
    );

    AppToast.show(
      message: result.success ? l10n.offerUpdated : l10n.somethingWentWrong,
      type: result.success ? AppToastType.success : AppToastType.error,
    );

    if (result.success) {
      navigation.revealClientOrders();
    }
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (ref.read(offerMutationProvider).isSubmitting) {
      return;
    }

    final notifier = ref.read(offerMutationProvider.notifier);
    final result = await notifier.rejectOffer(
      offer.id,
      chatId: offer.chatId,
      requestId: offer.requestId,
    );

    if (!context.mounted) return;

    AppToast.show(
      message: result.success ? l10n.offerUpdated : l10n.somethingWentWrong,
      type: result.success ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final mutedText = colorScheme.onSurfaceVariant;
    final priceColor = AppTheme.brandTintFg(theme.brightness);

    final equipment = offer.equipment;
    final ownerComment = offer.comment?.trim();

    final isHandled =
        offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.rejected ||
        offer.status == OfferStatus.expired;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          /// OWNER HEADER
          Row(
            children: [
              Expanded(child: UserInfoTile(user: offer.owner)),

              OfferStatusBadge(status: offer.status),
            ],
          ),

          const SizedBox(height: 14),

          /// EQUIPMENT CARD
          if (equipment != null) EquipmentInfoTile(equipment: equipment),

          const SizedBox(height: 16),

          /// OWNER COMMENT
          if (ownerComment != null && ownerComment.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ownerComment.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ownerComment,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Row(
            children: [
              /// OFFER RATE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.offeredRate.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${formatPrice(offer.price)} ${getPriceRate(offer.priceRate, l10n: l10n)}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: priceColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              /// ACTIONS
              if (offer.chatId.isNotEmpty) ...[
                AppIconButton(
                  onTap: () => context.push(
                    '${AppRoutes.clientChatList}/direct/${offer.chatId}',
                  ),
                  icon: LucideIcons.messageCircle,
                  tone: AppIconButtonTone.primary,
                ),

                const SizedBox(width: 8),
              ],

              if (!isHandled) ...[
                // Reject Offer
                AppIconButton(
                  onTap: () => ref.watch(offerMutationProvider).isSubmitting
                      ? null
                      : _handleReject(context, ref, l10n),
                  icon: LucideIcons.x,
                  tone: AppIconButtonTone.destructive,
                ),

                const SizedBox(width: 8),

                // Accept Offer
                AppIconButton(
                  onTap: () => ref.watch(offerMutationProvider).isSubmitting
                      ? null
                      : _handleAccept(context, ref, l10n),
                  icon: LucideIcons.check,
                  tone: AppIconButtonTone.success,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
