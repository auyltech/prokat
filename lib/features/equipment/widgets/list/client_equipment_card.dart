import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';

class ClientEquipmentCard extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const ClientEquipmentCard({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authSession = ref.watch(authProvider).session;
    final isClient = authSession != null;

    final notifier = ref.read(favoriteProvider.notifier);
    final bool isFavorite = notifier.isFavorite(equipment.id);

    final priceEntry = equipment.prices.isNotEmpty
        ? equipment.prices.first
        : null;
    final priceRate = getPriceRate(priceEntry?.priceRate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24), // Softer corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), // Much softer shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          /// 1. IMAGE SECTION (Clean & Floating Elements)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Image.network(
                  equipment.imageUrl ?? "",
                  height: 200, // Slightly taller for better presence
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Floating Badges
              Positioned(
                top: 16,
                left: 16,
                child: Row(
                  children: [
                    _badge(
                      text: equipment.status.toLowerCase() == "available"
                          ? "• ONLINE"
                          : "OFFLINE",
                      color: equipment.status.toLowerCase() == "available"
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _badge(
                      text: equipment.location?.city ?? "",
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              // Floating Favorite (Moved to top-right for cleaner look)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  color: isFavorite ? Colors.red : Colors.white,
                  iconSize: 28,
                  onPressed: isClient
                      ? () => notifier.toggleFavorite(equipment.id)
                      : null,
                ),
              ),
            ],
          ),

          /// 2. CONTENT SECTION
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equipment name + rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${equipment.name} ${equipment.model}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "4.5",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Owner under equipment name
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        equipment.owner?.displayName ?? "Owner",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Specs Row (Owner, Capacity, and Price integrated)
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${equipment.capacity} ${equipment.capacityUnit}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // The Price: Now a clean text element instead of a bubble
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          priceEntry != null ? "${priceEntry.price} ₸" : "POA",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: theme.primaryColor,
                          ),
                        ),
                        Text(
                          priceRate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 3. ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "RESERVE NOW",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// REUSABLE BADGE
  Widget _badge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
