import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/equipment/widgets/equipment_info_tile.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
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
    if (ref.read(offersProvider).isSubmitting ||
        ref.read(offersProvider).isLoading) {
      return;
    }

    final notifier = ref.read(offersProvider.notifier);

    final success = await notifier.acceptOffer(offer.id);

    if (!context.mounted) return;

    AppSnackBar.show(
      context,
      message: success ? l10n.offerUpdated : l10n.somethingWentWrong,
      isSuccess: success,
      isError: !success,
    );
  }

  Future<void> _handleReject(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (ref.read(offersProvider).isSubmitting ||
        ref.read(offersProvider).isLoading) {
      return;
    }

    final notifier = ref.read(offersProvider.notifier);
    final success = await notifier.rejectOffer(offer.id);

    if (!context.mounted) return;

    AppSnackBar.show(
      context,
      message: success ? l10n.offerUpdated : l10n.somethingWentWrong,
      isSuccess: success,
      isError: !success,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final owner = offer.owner;
    final equipment = offer.equipment;

    final ownerName = owner?.displayName ?? "";

    final ownerRating = owner?.rating?.toStringAsFixed(1) ?? "4.7";
    final totalOrders = owner?.orderCount ?? 0;

    final ownerComment = offer.comment?.trim();

    final isHandled =
        offer.status == OfferStatus.accepted ||
        offer.status == OfferStatus.rejected ||
        offer.status == OfferStatus.expired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// OWNER HEADER
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE3F2FD),
                backgroundImage:
                    owner?.imageUrl != null && owner!.imageUrl!.isNotEmpty
                    ? NetworkImage(owner.imageUrl!)
                    : null,
                child: owner?.imageUrl == null || owner!.imageUrl!.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Color(0xFF00599C),
                        size: 22,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF161616),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          ownerRating,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (totalOrders > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            "• $totalOrders orders",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "NEW OFFER",
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// EQUIPMENT CARD
          if (equipment != null) EquipmentInfoTile(equipment: equipment),

          const SizedBox(height: 16),

          /// OFFER RATE
          Row(
            children: [
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
            ],
          ),

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

          const SizedBox(height: 16),

          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEEEEEE)),

          const SizedBox(height: 12),

          /// ACTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (offer.chatId.isNotEmpty) ...[
                ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () => context.push(
                    '${AppRoutes.clientChatList}/${offer.chatId}',
                  ),
                ),

                const SizedBox(width: 8),
              ],

              if (!isHandled) ...[
                ActionButton.destructive(
                  label: l10n.reject,
                  isEnabled: !ref.watch(offersProvider).isSubmitting,
                  onPressed: () => ref.watch(offersProvider).isSubmitting
                      ? null
                      : _handleReject(context, ref, l10n),
                  isLoading: ref.watch(offersProvider).isSubmitting,
                ),

                const SizedBox(width: 8),

                ActionButton(
                  label: l10n.accept,
                  isEnabled: !ref.watch(offersProvider).isSubmitting,
                  onPressed: () => ref.watch(offersProvider).isSubmitting
                      ? null
                      : _handleAccept(context, ref, l10n),
                  isLoading: ref.watch(offersProvider).isSubmitting,
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: offer.status == OfferStatus.accepted
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    offer.status == OfferStatus.accepted
                        ? "ACCEPTED"
                        : "REJECTED",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: offer.status == OfferStatus.accepted
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
