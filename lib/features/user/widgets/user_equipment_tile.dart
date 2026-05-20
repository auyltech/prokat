import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

// TODO: DELETE

class UserEquipmentTile extends ConsumerWidget {
  final Equipment equipment;
  final VoidCallback onTap;
  final bool isRenter;

  const UserEquipmentTile({
    super.key,
    required this.equipment,
    required this.onTap,
    this.isRenter = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
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
              : ""
        : "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 100,
                height: 110,
                child: OptimizedNetworkImage(
                  imageUrl: displayUrl,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.precision_manufacturing_rounded,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            equipment.owner?.displayName ?? l10n.privateOwner,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        isFavorite == true
                            ? const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.favorite_border,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                              ),

                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "4.8 (24)",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        _StatusIndicator(status: equipment.status),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    Text(
                      "${equipment.model} • ${equipment.capacity} ${equipment.capacityUnit}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: accent),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location?.city ?? "",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          children: [
                            Text(
                              priceEntry != null
                                  ? "${priceEntry.price} ₸"
                                  : l10n.poa,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              priceRate,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
        color = Colors.green;
        break;
      case "BOOKED":
      case "BUSY":
        color = Colors.orange;
        break;
      case "MAINTENANCE":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
