import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

class GuestEquipmentCard extends StatelessWidget {
  final Equipment item;

  const GuestEquipmentCard({super.key, required this.item});

  static const double height = 94;

  void _showSignInDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.loginRequired),
            content: Text(l10n.loginRequiredToViewEquipment),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.cancel),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text(l10n.loginLink),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog

                  context.go(AppRoutes.login);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop = (item.owner?.rating ?? 0) >= 4.5;

    return GestureDetector(
      onTap: () => _showSignInDialog(context),
      child: Row(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Thumbnail ────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: OptimizedNetworkImage(
              imageUrl: item.imageUrl ?? "",
              width: 120,
              height: height,
              fit: BoxFit.contain,
              fallbackIcon: Icons.inventory_2_outlined,
            ),
          ),

          // ── Info ─────────────────────────────────────────────────────
          Expanded(
            child: SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusBadge(isTop: isTop),
                  const SizedBox(height: 3),

                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // TODO(Vadim): temp hided
                  // Text(
                  //   item.category?.name ?? "",
                  //   style: theme.textTheme.bodyMedium,
                  // ),
                  //
                  const Spacer(),

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

                      const Spacer(),
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
