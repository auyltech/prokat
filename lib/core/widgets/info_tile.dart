import 'package:flutter/material.dart';

enum InfoTileVariant { primary, secondary, ghost, destructive }

class InfoTile extends StatelessWidget {
  final String? label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  final InfoTileVariant variant;

  const InfoTile({
    super.key,
    this.label,
    required this.value,
    this.icon,
    this.onTap,
    this.variant = InfoTileVariant.primary,
  });

  factory InfoTile.ghost({
    Key? key,
    String? label,
    required String value,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return InfoTile(
      key: key,
      label: label,
      value: value,
      onTap: onTap,
      icon: icon,
      variant: InfoTileVariant.ghost,
    );
  }

  factory InfoTile.destructive({
    Key? key,
    String? label,
    required String value,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return InfoTile(
      key: key,
      label: label,
      value: value,
      onTap: onTap,
      icon: icon,
      variant: InfoTileVariant.destructive,
    );
  }

  factory InfoTile.secondary({
    Key? key,
    String? label,
    required String value,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return InfoTile(
      key: key,
      label: label,
      value: value,
      onTap: onTap,
      icon: icon,
      variant: InfoTileVariant.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (variant == InfoTileVariant.ghost) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label ?? "", style: theme.textTheme.labelSmall),
          Text(
            // Replace with your exact total price variable if different
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 12,
        ), // Increased padding slightly for multi-line layout comfort
        decoration: BoxDecoration(
          color: variant == InfoTileVariant.destructive
              ? Colors.red.shade50
              : theme.dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: variant == InfoTileVariant.destructive
                ? Colors.red.shade200
                : theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: label != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Switched to start for better multi-line text flow
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: theme.primaryColor, size: 20),
                        SizedBox(width: 6),
                      ],

                      Text(
                        label ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: variant == InfoTileVariant.destructive
                          ? Colors.red[700]
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (icon != null)
                    Icon(icon, color: theme.primaryColor, size: 20),

                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: variant == InfoTileVariant.destructive
                          ? Colors.red[700]
                          : Colors.black,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
