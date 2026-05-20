import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import '../../models/equipment_model.dart'; // Adjust path

class EquipmentListTile extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback onTap;
  final bool isRenter;

  const EquipmentListTile({
    super.key,
    required this.equipment,
    required this.onTap,
    this.isRenter = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const cardColor = Color(0xFF1E2125);
    const accentColor = Color(0xFF4E73DF);
    final l10n = AppLocalizations.of(context)!;

    final notifier = ref.read(favoriteProvider.notifier);
    final bool isFavorite = notifier.isFavorite(equipment.id);

    final displayUrl = equipment.imageUrl?.isNotEmpty == true
        ? equipment.imageUrl!
        : "https://insqvwqlfhbfcqqnvzxu.supabase.co/storage/v1/object/public/Media/kamaz1.jpg";

    final priceEntry = equipment.prices.isNotEmpty
        ? equipment.prices.first
        : null;
    final location = equipment.location;

    final priceRate = priceEntry != null
        ? priceEntry.priceRate.toUpperCase() == "PER_TRIP"
              ? l10n.perTrip
              : priceEntry.priceRate.toUpperCase() == "PER_CUBIC_METER"
              ? l10n.perM3
              : priceEntry.priceRate.toUpperCase() == "PER_HOUR"
              ? l10n.perHour
              : priceEntry.priceRate.toUpperCase()
        : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 1. IMAGE (Filled to left edges)
                SizedBox(
                  width: 120,
                  child: OptimizedNetworkImage(
                    imageUrl: displayUrl,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.precision_manufacturing_rounded,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                  ),
                ),

                /// 2. CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Owner & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                equipment.owner?.displayName.toUpperCase() ??
                                    l10n.privateOwner,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isFavorite)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 14,
                                ),
                              ),
                            _StatusIndicator(status: equipment.status),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Equipment Name
                        Text(
                          equipment.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Model & Capacity
                        Text(
                          "${equipment.model} • ${equipment.capacity} ${equipment.capacityUnit}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Reviews & Location Row
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "4.8 (24)",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Price Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${location?.street}, ${location?.city} • 5.2 km",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              priceEntry != null
                                  ? "${priceEntry.price} ₸ "
                                  : "POA",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              priceRate,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String status;
  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case "AVAILABLE":
        color = Colors.greenAccent;
        break;
      case "BOOKED":
      case "BUSY":
        color = Colors.orangeAccent;
        break;
      case "MAINTENANCE":
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
        ],
      ),
    );
  }
}
