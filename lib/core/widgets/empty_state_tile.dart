import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/base_tile.dart';

class EmptyStateTile extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? imageName;
  final Color? color;
  final Widget? actionButton;

  const EmptyStateTile({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.imageName,
    this.color,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.outline;
    final hasImage = imageName?.trim().isNotEmpty ?? false;

    return BaseTile(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasImage) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/media/$imageName',
                  height: 200,
                  width: 340,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else if (icon != null) ...[
            Icon(icon, color: displayColor, size: 32),
            const SizedBox(height: 12),
          ],

          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium,
            ),
          ],

          if (actionButton != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: actionButton,
            ),
        ],
      ),
    );
  }
}
