import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/widgets/offer_status_badge.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';

class OfferTile extends ConsumerWidget {
  final OfferModel offer;

  const OfferTile({super.key, required this.offer});

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (ref.read(offersProvider).isFetching ||
        ref.read(offersProvider).isSubmitting) {
      return;
    }

    final notifier = ref.read(offersProvider.notifier);

    final result = await notifier.acceptOffer(offer.id);

    if (!context.mounted) return;

    AppSnackBar.show(
      message: result.success ? l10n.offerUpdated : l10n.somethingWentWrong,
      isSuccess: result.success,
      isError: !result.success,
    );
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (ref.read(offersProvider).isSubmitting ||
        ref.read(offersProvider).isFetching) {
      return;
    }

    final notifier = ref.read(offersProvider.notifier);
    final result = await notifier.rejectOffer(offer.id);

    if (!context.mounted) return;

    AppSnackBar.show(
      message: result.success ? l10n.offerUpdated : l10n.somethingWentWrong,
      isSuccess: result.success,
      isError: !result.success,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final equipment = offer.equipment;
    final ownerComment = offer.comment?.trim();

    final isHandled =
        offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.rejected ||
        offer.status == OfferStatus.expired;

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// OWNER HEADER
          Row(
            children: [
              UserInfoTile(user: offer.owner),

              Spacer(),

              OfferStatusBadge(status: offer.status),

              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 12,
              //     vertical: 6,
              //   ),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFE8F5E9),
              //     borderRadius: BorderRadius.circular(6),
              //   ),
              //   child: Text(
              //     "NEW OFFER",
              //     style: const TextStyle(
              //       color: Color(0xFF2E7D32),
              //       fontSize: 11,
              //       fontWeight: FontWeight.w800,
              //       letterSpacing: 0.3,
              //     ),
              //   ),
              // ),
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
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "OWNER COMMENT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ownerComment,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF424242),
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${formatPrice(offer.price)} ${getPriceRate(offer.priceRate, l10n: l10n)}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0D47A1),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              /// ACTIONS
              if (offer.chatId.isNotEmpty) ...[
                IconButton(
                  onPressed: () => context.push(
                    '${AppRoutes.clientChatList}/direct/${offer.chatId}',
                  ),
                  icon: Icon(
                    LucideIcons.messageCircle,
                    size: 25,
                    color: theme.primaryColor,
                  ),
                ),

                const SizedBox(width: 8),
              ],

              if (!isHandled) ...[
                // Reject Offer
                IconButton(
                  onPressed: () => ref.watch(offersProvider).isSubmitting
                      ? null
                      : _handleReject(context, ref, l10n),
                  icon: Icon(
                    LucideIcons.x,
                    size: 25,
                    color: theme.colorScheme.error,
                  ),
                ),

                const SizedBox(width: 8),

                // Accept Offer
                IconButton(
                  onPressed: () => ref.watch(offersProvider).isSubmitting
                      ? null
                      : _handleAccept(context, ref, l10n),
                  icon: Icon(
                    LucideIcons.check,
                    size: 25,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
