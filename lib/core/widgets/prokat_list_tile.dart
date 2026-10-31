import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';

class ProkatListTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? variant;
  final String? statusLine;
  final Color? statusColor;
  final IconData? statusIcon;

  const ProkatListTile({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.variant = "default",
    this.statusLine,
    this.statusColor,
    this.statusIcon,
  });

  factory ProkatListTile.secondary({
    Key? key,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? statusLine,
    Color? statusColor,
    IconData? statusIcon,
  }) {
    return ProkatListTile(
      key: key,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      onTap: onTap,
      subtitle: subtitle,
      title: title,
      variant: "secondary",
      statusLine: statusLine,
      statusColor: statusColor,
      statusIcon: statusIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = ProkatFlowScope.maybeOf(context);
    final statusText = statusLine?.trim();
    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: flow?.primarySoft ?? iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: flow?.primary ?? iconColor, size: 23),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: variant == "secondary"
                      ? theme.textTheme.labelSmall?.copyWith(
                          color:
                              flow?.secondary ??
                              theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                        )
                      : theme.textTheme.bodyMedium?.copyWith(
                          color: flow?.title,
                          fontWeight: FontWeight.w500,
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: variant == "secondary"
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: flow?.title,
                          fontWeight: FontWeight.w500,
                        )
                      : theme.textTheme.labelSmall?.copyWith(
                          color:
                              flow?.secondary ??
                              theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              ),
                        ),
                ),
                if (statusText != null && statusText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (statusIcon != null) ...[
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor ?? theme.colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          statusText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor ?? theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            color: flow?.secondary ?? theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
    if (flow == null) return tile;
    return Material(
      color: flow.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: flow.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(14), child: tile),
    );
  }
}
