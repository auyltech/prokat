import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';

class FavoriteTile extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const FavoriteTile({super.key, required this.equipment, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Check favorite status to handle the "Un-favorite" action
    final isFavorite =
        ref.watch(
          favoriteProvider.select(
            (s) => s.favoritesIds?.contains(equipment.id),
          ),
        ) ??
        false;

    final location = equipment.location?.city ?? "Unknown location";

    final price = equipment.prices.isNotEmpty
        ? "${equipment.prices.first.price} ₸/${equipment.prices.first.priceRate}"
        : "No price";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12), // Reduced padding for tighter list
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              /// IMAGE
              Hero(
                tag: 'equip-${equipment.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: OptimizedNetworkImage(
                    imageUrl: equipment.imageUrl ?? "",
                    height: 80,
                    width: 80, // Square image looks better in lists
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.broken_image_outlined,
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              /// DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      equipment.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: theme.hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(location, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              /// ACTIONS
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => ref
                        .read(favoriteProvider.notifier)
                        .toggleFavorite(equipment.id),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : theme.hintColor,
                      size: 22,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.hintColor.withValues(alpha: 0.3),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
