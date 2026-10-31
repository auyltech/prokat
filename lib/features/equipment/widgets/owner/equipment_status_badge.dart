import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentStatusBadge extends StatelessWidget {
  final EquipmentStatus status;

  const EquipmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color statusColor = status == EquipmentStatus.available
        ? const Color.fromARGB(255, 24, 143, 0)
        : status == EquipmentStatus.booked
        ? const Color.fromARGB(255, 255, 102, 13)
        : status == EquipmentStatus.maintenance
        ? const Color.fromARGB(255, 255, 0, 0)
        : const Color.fromARGB(255, 131, 131, 131);

    final statusString = status == EquipmentStatus.draft
        ? l10n.statusDraft
        : status == EquipmentStatus.created
        ? l10n.moderatorReview
        : status == EquipmentStatus.accepted ||
              status == EquipmentStatus.available
        ? l10n.statusVerified
        : status == EquipmentStatus.rejected
        ? l10n.resubmit
        : status == EquipmentStatus.booked
        ? l10n.booked
        : status == EquipmentStatus.maintenance
        ? l10n.maintenance
        : '';

    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      final color = switch (status) {
        EquipmentStatus.available || EquipmentStatus.accepted => flow.success,
        EquipmentStatus.created || EquipmentStatus.booked => flow.primary,
        EquipmentStatus.rejected ||
        EquipmentStatus.maintenance => Theme.of(context).colorScheme.error,
        _ => flow.secondary,
      };
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          statusString.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: color,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120, minHeight: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          statusString.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textWidthBasis: TextWidthBasis.longestLine,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            height: 1.15,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
