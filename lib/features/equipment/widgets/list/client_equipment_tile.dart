import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_spec.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientEquipmentTile extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const ClientEquipmentTile({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authSession = ref.watch(authProvider).session;
    final isClient = authSession != null;

    final favoritesIds = ref.watch(favoritesProvider).favoritesIds;
    final bool isFavorite = favoritesIds?.contains(equipment.id) ?? false;
    final notifier = ref.read(favoritesProvider.notifier);

    final priceEntry = equipment.prices.isNotEmpty
        ? equipment.prices.first
        : null;

    final priceRate = getPriceRate(priceEntry?.priceRate, l10n: l10n);

    return BaseTile(
      padding: EdgeInsets.all(0),
      // decoration: BoxDecoration(
      //   color: theme.cardColor,
      //   borderRadius: BorderRadius.circular(24), // Softer corners
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withValues(alpha: 0.4), // Much softer shadow
      //       blurRadius: 2,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      // ),
      child: Column(
        children: [
          /// 1. IMAGE SECTION (Clean & Floating Elements)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: OptimizedNetworkImage(
                  imageUrl: equipment.imageUrl ?? "",
                  height: 200, // Slightly taller for better presence
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.precision_manufacturing_outlined,
                ),
              ),

              // Floating Badges
              Positioned(
                top: 16,
                left: 16,
                child: Row(
                  children: [
                    _badge(
                      text: equipment.status == EquipmentStatus.available
                          ? "• ${l10n.online}"
                          : l10n.offline,
                      color: equipment.status == EquipmentStatus.available
                          ? Colors.green
                          : Colors.grey,
                    ),
                    if (equipment.city!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _badge(
                        text: equipment.city ?? "",
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ],
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
                  color: Colors.red,
                  iconSize: 28,
                  onPressed: isClient
                      ? () => notifier.toggleFavorite(equipment.id)
                      : null,
                ),
              ),

              // Price
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer.withValues(
                      alpha: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        priceEntry == null
                            ? "POA"
                            : formatPrice(priceEntry.price),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        priceRate,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color.fromARGB(255, 65, 65, 65),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// 2. CONTENT SECTION
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equipment name + rating
                Text(
                  equipment.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Text(
                //   equipment.model,
                //   style: theme.textTheme.titleSmall,
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                // ),

                // Owner under equipment name
                Row(
                  children: [
                    // Icon(
                    //   Icons.person_outline,
                    //   size: 16,
                    //   color: theme.colorScheme.onSurface.withValues(
                    //     alpha: 0.55,
                    //   ),
                    // ),
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
                        letterSpacing: -.5,
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
                buildSpecsGrid(context, equipment.specs ?? [], theme),

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
                    child: Text(
                      l10n.reserveNow.toUpperCase(),
                      style: const TextStyle(
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

IconData _getIconData(String? library, String? name) {
  if (name == null || name.isEmpty) return Icons.star_border;

  final lowerName = name.toLowerCase();

  // 1. Lucide Icons Parsing
  if (library?.toLowerCase() == 'lucide' ||
      library?.toLowerCase() == 'lucideicons') {
    switch (lowerName) {
      case 'straighten':
      case 'ruler':
        return LucideIcons.ruler;
      case 'weight':
        return LucideIcons.scale;
      case 'settings':
      case 'cog':
        return LucideIcons.cog;
      case 'zap':
      case 'bolt':
        return LucideIcons.bold;
      default:
        return LucideIcons.info;
    }
  }

  // 2. Material Icons Fallback Parsing
  switch (lowerName) {
    case 'straighten':
      return Icons.straighten;
    case 'scale':
    case 'weight':
      return Icons.scale;
    case 'flash_on':
    case 'bolt':
      return Icons.flash_on;
    case 'settings':
      return Icons.settings;
    default:
      return Icons.star_border;
  }
}

Widget buildSpecsGrid(
  BuildContext context,
  List<EquipmentSpec>? specs,
  ThemeData theme,
) {
  // If the list is null or empty, don't allocate screen rendering space
  if (specs == null || specs.isEmpty) return const SizedBox.shrink();

  // Take a maximum slice of 4 items to strictly honor your layout requirement
  final displaySpecs = specs.take(4).toList();

  return Wrap(
    spacing: 12.0, // Horizontal gap spacing between spec pills
    runSpacing: 8.0, // Vertical gap line spacing if wrapping occurs
    alignment: WrapAlignment.start,
    children: displaySpecs.map((spec) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Allows items to hug their own content
          children: [
            // Safe Dynamic Icon Loader
            Icon(
              _getIconData(spec.iconLibrary, spec.iconName),
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 6),

            // Constrain text blocks inside dynamically sizing horizontal arrays
            Flexible(
              child: Text(
                "${spec.name}: ${spec.value ?? ""}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
