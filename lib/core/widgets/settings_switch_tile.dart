import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;
  final bool? isLoading;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    this.iconBgColor,
    this.iconColor,
    this.onTap,
    this.isLoading,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = ProkatFlowScope.maybeOf(context);

    final tile = GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
                  flow?.primarySoft ??
                  iconBgColor ??
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: flow == null ? 32 : 23,
              color: flow?.primary ?? iconColor ?? theme.colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          isLoading == true
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: flow == null
                      ? const Color(0xFF4E73DF)
                      : Colors.white,
                  activeTrackColor: flow?.primary,
                  inactiveThumbColor: flow == null ? null : Colors.white,
                  inactiveTrackColor: flow?.secondary,
                ),
        ],
      ),
    );
    if (flow == null) return tile;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: flow.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: flow.border),
      ),
      child: tile,
    );
  }
}
