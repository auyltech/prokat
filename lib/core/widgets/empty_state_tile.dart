import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/empty_state_artwork.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

class EmptyStateTile extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? imageName;
  final double imageHeight;
  final BoxFit imageFit;
  final Color? color;
  final Widget? actionButton;
  final bool compact;

  const EmptyStateTile({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.imageName,
    this.imageHeight = 200,
    this.imageFit = BoxFit.cover,
    this.color,
    this.actionButton,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = ProkatFlowScope.maybeOf(context);
    final subtitleStyle = flow == null
        ? theme.textTheme.labelMedium
        : theme.textTheme.bodyMedium?.copyWith(
            color: flow.secondary,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            height: 1.5,
          );
    final displayColor = color ?? theme.colorScheme.outline;
    final hasImage = imageName?.trim().isNotEmpty ?? false;
    final hasArtwork = EmptyStateArtwork.supports(imageName);

    if (compact) {
      return AppCard(
        child: Row(
          children: [
            if (hasArtwork) ...[
              EmptyStateArtwork(imageName: imageName!, compact: true),
              const SizedBox(width: 16),
            ] else if (hasImage) ...[
              Image.asset(
                'assets/media/$imageName',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null)
                    Text(title!, style: theme.textTheme.bodyLarge),
                  if (subtitle != null) Text(subtitle!, style: subtitleStyle),
                  if (actionButton != null) ...[
                    const SizedBox(height: 12),
                    actionButton!,
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.s20$lg),
      radius: AppDimens.r20$xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasArtwork) ...[
            Center(child: EmptyStateArtwork(imageName: imageName!)),
            const SizedBox(height: 12),
          ] else if (hasImage) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/media/$imageName',
                  height: imageHeight,
                  width: 340,
                  fit: imageFit,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            SizedBox(height: actionButton != null ? 4 : 12),
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
            Text(subtitle!, textAlign: TextAlign.center, style: subtitleStyle),
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
