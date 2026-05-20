import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_status_badge.dart';
import 'package:prokat/features/equipment/widgets/owner/online_toggle.dart';

class OwnerEquipmentCard extends ConsumerWidget {
  final Equipment equipment;

  const OwnerEquipmentCard({super.key, required this.equipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.5);

    final locationText = equipment.city ?? "No location set";
    final priceEntry = equipment.prices.firstOrNull;
    final hasPrice = priceEntry != null;

    final priceDisplay = hasPrice
        ? "${priceEntry.price} ${getPriceRate(priceEntry.priceRate)}"
        : "No Price Set";

    return InkWell(
      onTap: () {
        ref.read(equipmentProvider.notifier).selectEditEquipment(equipment);
        context.push('${AppRoutes.ownerEquiment}/${equipment.id}');
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ROW 1: Identity Profile
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(equipment.imageUrl),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  equipment.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              EquipmentStatusBadge(status: equipment.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${equipment.model.toUpperCase()} ${equipment.plateNumber != null ? '• ${equipment.plateNumber!.toUpperCase()}' : ''}",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ghostGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: ghostGray,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                locationText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ghostGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 2, thickness: 0.3),
                ),

                // ROW 2: Pricing Strategy & Online Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price Indicators
                    Row(
                      children: [
                        Tooltip(
                          message: hasPrice
                              ? "Has prices listed"
                              : "No prices listed",
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(
                            hasPrice
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            size: 18,
                            color: hasPrice ? Colors.green : colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priceDisplay,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: hasPrice ? colorScheme.primary : ghostGray,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Active Live Toggle
                    if (equipment.status == "AVAILABLE" ||
                        equipment.status == "ACCEPTED")
                      Row(
                        children: [
                          Text(
                            "Online",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ghostGray,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 24,
                            child: OnlineToggle(
                              id: equipment.id,
                              isVisible: equipment.isVisible,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: OptimizedNetworkImage(
        imageUrl: url ?? "",
        width: 120,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }
}
