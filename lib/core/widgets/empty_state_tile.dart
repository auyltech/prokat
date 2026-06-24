import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/base_tile.dart';

class EmptyStateTile extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const EmptyStateTile({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.outline;

    return BaseTile(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            Icon(icon, color: displayColor, size: 32),
            const SizedBox(height: 12),
          ],
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
