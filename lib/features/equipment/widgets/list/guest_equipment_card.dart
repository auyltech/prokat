import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

class GuestEquipmentCard extends StatelessWidget {
  final Equipment item;
  const GuestEquipmentCard({super.key, required this.item});

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isTop = item.rating >= 4.9;
    final isTop = true;

    return Container(
      height: 130,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Thumbnail ────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: OptimizedNetworkImage(
              imageUrl: item.imageUrl ?? "",
              width: 100,
              height: 76,
              fit: BoxFit.contain,
              fallbackIcon: Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ─────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.category?.name ?? "",
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.star_rate_rounded,
                        size: 20,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "4.8", //item.rating.toStringAsFixed(1)
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusBadge(isTop: isTop),

                SizedBox(height: 20),

                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${_formatPrice(item.prices.isEmpty ? 0 : item.prices[0].price.floorToDouble())} ₸',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ${AppLocalizations.of(context)!.perDay}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isTop;
  const _StatusBadge({required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTop ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0),
          width: 0.5,
        ),
      ),
      child: Text(
        isTop
            ? AppLocalizations.of(context)!.topRated
            : AppLocalizations.of(context)!.available,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isTop ? const Color(0xFF9A3412) : const Color(0xFF166534),
        ),
      ),
    );
  }
}
