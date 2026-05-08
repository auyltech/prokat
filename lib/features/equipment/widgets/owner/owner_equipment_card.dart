import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';

class OwnerEquipmentCard extends ConsumerWidget {
  final Equipment equipment;

  const OwnerEquipmentCard({super.key, required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Theme-based colors
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.5);

    final locationText = equipment.city ?? "No location set";

    final priceEntry = equipment.prices.firstOrNull;
    final priceDisplay = priceEntry != null
        ? "${priceEntry.price} ${getPriceRate(priceEntry.priceRate)}"
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

              _StatusBadge(status: equipment.status),
            ],
          ),

          SizedBox(height: 12),

          // const Padding(
          //   padding: EdgeInsets.symmetric(vertical: 12),
          //   child: Divider(height: 1),
          // ),

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

              Spacer(),

              Spacer(),

              // Online Toggle
              _onlineToggle(context, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url ?? "",
        width: 110,
        height: 70,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade100,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _onlineToggle(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "ONLINE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: equipment.isVisible
                ? const Color.fromARGB(255, 0, 160, 5)
                : const Color.fromARGB(255, 218, 0, 0),
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: equipment.isVisible,
            activeThumbColor: const Color(0xFF4E73DF),
            onChanged: (val) async {
              await ref
                  .read(equipmentProvider.notifier)
                  .updateVisibilityStatus(equipment.id, val, equipment.status);
            },
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status.toLowerCase() == 'available'
        ? const Color.fromARGB(255, 24, 143, 0)
        : status.toLowerCase() == 'booked'
        ? const Color.fromARGB(255, 255, 102, 13)
        : status.toLowerCase() == 'maintenance'
        ? const Color.fromARGB(255, 255, 0, 0)
        : const Color.fromARGB(255, 131, 131, 131);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, // White background to show the shadow
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: statusColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
