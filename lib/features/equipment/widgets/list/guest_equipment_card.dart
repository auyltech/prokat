import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

class GuestEquipmentCard extends StatelessWidget {
  final Equipment item;
  const GuestEquipmentCard({super.key, required this.item});

  void _showSignInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login is required'),
          content: const Text(
            'You need to login to view details and reserve equipment.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Login'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                context.push(AppRoutes.login); // Go to auth screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop = (item.owner?.rating ?? 0) >= 4.5;

    return BaseTile(
      onTap: () {
        _showSignInDialog(context);
      },
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
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

          // ── Info ─────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  Row(
                    children: [
                      Text(
                        item.category?.name ?? "",
                        style: theme.textTheme.bodyMedium,
                      ),
                      Spacer(),
                      _StatusBadge(isTop: isTop),
                    ],
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
                        (item.owner?.rating ?? 0).toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),

                      Spacer(),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: formatPrice(
                                item.prices.isEmpty
                                    ? 0
                                    : item.prices[0].price.floorToDouble(),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            TextSpan(
                              text: ' ${AppLocalizations.of(context)!.perDay}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    final l10n = AppLocalizations.of(context)!;

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
        isTop ? l10n.topRated : l10n.available,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isTop ? const Color(0xFF9A3412) : const Color(0xFF166534),
        ),
      ),
    );
  }
}
