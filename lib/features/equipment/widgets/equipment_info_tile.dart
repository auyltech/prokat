import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';

class EquipmentInfoTile extends StatelessWidget {
  final EquipmentSummaryModel equipment;

  const EquipmentInfoTile({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final imageUrl = equipment.imageUrl ?? "";
    final equipmentName = equipment.name ?? "";
    final equipmentModel = equipment.model ?? "";

    return Row(
        children: [
          SizedBox(
            width: 72,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: OptimizedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fallbackIcon: Icons.local_shipping,
                backgroundColor: const Color(0xFFE0E0E0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipmentName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF212121),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  equipmentModel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }
}
