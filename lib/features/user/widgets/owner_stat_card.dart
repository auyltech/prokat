import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/base_tile.dart';

class OwnerStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final IconData icon;
  final VoidCallback? onTap;

  const OwnerStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BaseTile(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.onSurface),

          const SizedBox(width: 8),

          Spacer(),

          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),

          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
