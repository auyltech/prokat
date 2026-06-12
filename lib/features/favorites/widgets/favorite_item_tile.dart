import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:go_router/go_router.dart';

class FavoriteItemTile extends ConsumerWidget {
  final Equipment equipment;

  const FavoriteItemTile({super.key, required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Watch the favorite status to ensure UI updates immediately
    final isFavorite =
        ref.watch(
          favoritesProvider.select(
            (s) => s.favoritesIds?.contains(equipment.id),
          ),
        ) ??
        false;

    final priceEntry = equipment.prices.isNotEmpty
        ? equipment.prices.first
        : null;

    return GestureDetector(
      onTap: () => context.push('/equipment/${equipment.id}/book'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(
            24,
          ), // Match the main equipment card style
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. IMAGE SECTION
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: OptimizedNetworkImage(
                    imageUrl: equipment.imageUrl ?? "",
                    height: 120, // Slightly taller for better aspect ratio
                    width: double.infinity,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.broken_image_outlined,
                    backgroundColor: theme.colorScheme.surfaceBright,
                  ),
                ),
                // Clean glass-effect favorite toggle
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(equipment.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// 2. INFO SECTION
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${equipment.name} ${equipment.model}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceEntry != null ? "${priceEntry.price} ₸" : "POA",
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      // Tiny star rating to fill space elegantly
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            "4.5",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Removed the 'Open' button - instead, make the whole card clickable
            // by wrapping this Container in an InkWell outside.
          ],
        ),
      ),
    );
  }
}
