import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentEmptyTile extends StatelessWidget {
  final String? title;
  final String? description;
  final IconData? icon;

  const EquipmentEmptyTile({
    super.key,
    this.title,
    this.description,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final flow = ProkatFlowScope.maybeOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color:
            flow?.surface ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              flow?.border ??
              theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
                flow?.primarySoft ?? theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              icon ?? Icons.inventory_2_outlined,
              color:
                  flow?.primary ??
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title ?? l10n.noEquipmentAvailable,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: flow?.title ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description ?? l10n.noEquipmentMatchingCategory,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  flow?.secondary ??
                  theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
