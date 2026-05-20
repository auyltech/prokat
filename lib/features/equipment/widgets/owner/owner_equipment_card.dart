import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_status_badge.dart';
import 'package:prokat/features/equipment/widgets/owner/online_toggle.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerEquipmentCard extends ConsumerWidget {
  final Equipment equipment;

  const OwnerEquipmentCard({super.key, required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;

    // Theme-based colors
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.5);

    final locationText = equipment.city ?? "No location set";

    final priceEntry = equipment.prices.firstOrNull;
    final priceDisplay = priceEntry != null
        ? "${priceEntry.price} ${getPriceRate(priceEntry.priceRate, l10n: l10n)}"
        : "No Price Set";

    return BaseTile(
      child: Column(
        children: [
          // TOP ROW: Image, Info, and Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(equipment.imageUrl),

              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(equipmentProvider.notifier)
                        .selectEditEquipment(equipment);
                    context.push('${AppRoutes.ownerEquiment}/${equipment.id}');
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.name,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        equipment.model.toUpperCase(),
                        style: theme.textTheme.labelMedium,
                      ),
                      Text(
                        equipment.plateNumber?.toUpperCase() ?? "",
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // BOTTOM ROW: Location, Price, and Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: ghostGray),
                      const SizedBox(width: 4),
                      Text(locationText, style: theme.textTheme.bodyMedium),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    priceDisplay,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  EquipmentStatusBadge(status: equipment.status),

                  if (equipment.status == "AVAILABLE" ||
                      equipment.status == "ACCEPTED")
                    // Online Toggle
                    OnlineToggle(
                      id: equipment.id,
                      isVisible: equipment.isVisible,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: OptimizedNetworkImage(
        imageUrl: url ?? "",
        width: 110,
        height: 70,
        fit: BoxFit.cover,
      ),
    );
  }
}
