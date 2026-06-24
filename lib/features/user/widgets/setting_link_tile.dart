import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/widgets/base_tile.dart';

class SettingsLinkTile extends StatelessWidget {
  final IconData icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SettingsLinkTile({
    super.key,
    required this.icon,
    this.iconBgColor,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: BaseTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        // decoration: BoxDecoration(
        //   color: theme.colorScheme.surface,
        //   borderRadius: BorderRadius.circular(14),
        //   border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        // ),
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
