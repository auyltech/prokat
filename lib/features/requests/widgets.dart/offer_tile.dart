import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';

class OfferTile extends ConsumerWidget {
  final OfferModel offer;

  const OfferTile({super.key, required this.offer});

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
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

    final imageUrl = equipment?.imageUrl ?? "";
    final equipmentName = equipment?.name ?? "";
    final equipmentModel = equipment?.model ?? "";

    final ownerComment = offer.comment?.trim();

    final isHandled =
        offer.status == "ACCEPTED" ||
        offer.status == "DECLINED" ||
        offer.status == "REJECTED";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: OptimizedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.local_shipping,
                      backgroundColor: const Color(0xFFE0E0E0),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipmentName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF212121),
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        equipmentModel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // if (capacity.isNotEmpty) ...[
                      //   const SizedBox(height: 2),
                      //   Text(
                      //     capacity,
                      //     style: theme.textTheme.bodySmall?.copyWith(
                      //       color: const Color(0xFF616161),
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    context.push('${AppRoutes.chat}/${offer.chatId}');
                  },
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 8),
              ],

              if (!isHandled) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _handleReject(context, ref, l10n),
                  child: Text(
                    l10n.reject,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _handleAccept(context, ref, l10n),
                  child: Text(
                    l10n.accept,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: offer.status == "ACCEPTED"
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    offer.status == "ACCEPTED" ? "ACCEPTED" : "REJECTED",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: offer.status == "ACCEPTED"
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
