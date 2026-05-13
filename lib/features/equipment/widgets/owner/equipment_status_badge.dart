import 'package:flutter/material.dart';

class EquipmentStatusBadge extends StatelessWidget {
  final String status;

  const EquipmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status.toLowerCase() == 'available'
        ? const Color.fromARGB(255, 24, 143, 0)
        : status.toLowerCase() == 'booked'
        ? const Color.fromARGB(255, 255, 102, 13)
        : status.toLowerCase() == 'maintenance'
        ? const Color.fromARGB(255, 255, 0, 0)
        : const Color.fromARGB(255, 131, 131, 131);

    final statusString = status.toLowerCase() == 'draft'
        ? 'draft'
        : status.toLowerCase() == 'created'
        ? 'Moderator Review'
        : status.toLowerCase() == 'available' ||
              status.toLowerCase() == 'accepted'
        ? 'Available'
        : status.toLowerCase() == 'rejected'
        ? 'Resubmit'
        : status.toLowerCase() == 'maintenance'
        ? 'Maintenance'
        : '';

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
        statusString.toUpperCase(),
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
