import 'package:flutter/material.dart';

class UserProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserProfileTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          /// Icon container
          Container(
            // padding: const EdgeInsets.all(10),
            // decoration: BoxDecoration(
            //   color: colorScheme.primary.withValues(alpha: 0.1),
            //   borderRadius: BorderRadius.circular(12),
            // ),
            child: Icon(icon, size: 32, color: colorScheme.primary),
          ),

          const SizedBox(width: 12),

          /// Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, style: textTheme.bodyMedium),
              ],
            ),
          ),

          /// Optional trailing widget
          trailing ?? const SizedBox(),
        ],
      ),
    );
  }
}
