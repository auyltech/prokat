import 'package:flutter/material.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentModerationStatusCard extends StatelessWidget {
  final EquipmentStatus status;

  const EquipmentModerationStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    late final String title;
    late final String subtitle;
    late final IconData icon;
    late final Color color;

    switch (status) {
      case EquipmentStatus.created:
        title = l10n.statusUnderReview;
        subtitle = l10n.statusUnderReviewSubtitle;
        icon = Icons.hourglass_top_rounded;
        color = colors.primary;
      case EquipmentStatus.rejected:
        title = l10n.statusRejected;
        subtitle = l10n.statusRejectedSubtitle;
        icon = Icons.error_outline_rounded;
        color = colors.error;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
