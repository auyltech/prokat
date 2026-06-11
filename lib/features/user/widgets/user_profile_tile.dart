import 'package:flutter/material.dart';

class UserProfileTile extends StatelessWidget {
  final IconData icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserProfileTile({
    super.key,
    required this.icon,
    this.iconBgColor,
    this.iconColor,
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBgColor ?? theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),

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
      ),
    );
  }
}
