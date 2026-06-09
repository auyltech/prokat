import 'package:flutter/material.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

class EquipmentStatusBadge extends StatelessWidget {
  final EquipmentStatus status;

  const EquipmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status == EquipmentStatus.available
        ? const Color.fromARGB(255, 24, 143, 0)
        : status == EquipmentStatus.booked
        ? const Color.fromARGB(255, 255, 102, 13)
        : status == EquipmentStatus.maintenance
        ? const Color.fromARGB(255, 255, 0, 0)
        : const Color.fromARGB(255, 131, 131, 131);

    final statusString = status == EquipmentStatus.draft
        ? 'draft'
        : status == EquipmentStatus.created
        ? 'Moderator Review'
        : status == EquipmentStatus.accepted ||
              status == EquipmentStatus.available
        ? 'Available'
        : status == EquipmentStatus.rejected
        ? 'Resubmit'
        : status == EquipmentStatus.maintenance
        ? 'Maintenance'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor, // White background to show the shadow
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusString.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
