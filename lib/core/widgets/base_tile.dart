import 'package:flutter/material.dart';

class BaseTile extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const BaseTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.width,
    this.color,
    this.borderColor,
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resolvedColor = color ?? theme.cardColor;
    final resolvedBorderColor =
        borderColor ?? theme.dividerColor.withValues(alpha: 0.4);

    final decoration = BoxDecoration(
      color: resolvedColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: resolvedBorderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    );

    if (onTap != null) {
      // Material + InkWell so splash paints above the card fill.
      return Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: decoration.boxShadow,
        ),
        child: Material(
          color: resolvedColor,
          borderRadius: BorderRadius.circular(borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.06),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: resolvedBorderColor),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}
