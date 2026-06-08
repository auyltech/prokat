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

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),

          const SizedBox(width: 12),

          /// Main content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // label
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
                // Main Text
                Text(value, style: theme.textTheme.bodyLarge),
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
