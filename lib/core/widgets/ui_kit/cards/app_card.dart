import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';

/// Shared surface; refreshed screens opt into a flat Flow border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double radius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.cardPadding),
    this.width,
    this.radius = AppDimens.cardRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = context.colors.card;
    final flow = ProkatFlowScope.maybeOf(context);
    final ripple = context.colors.ripple;
    final borderRadius = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: flow != null
            ? const []
            : [
                BoxShadow(
                  color: cardTheme.shadow,
                  blurRadius: AppDimens.cardShadowBlurRadius,
                  offset: const Offset(0, AppDimens.cardShadowOffsetY),
                ),
              ],
      ),
      child: Material(
        color: flow?.surface ?? cardTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(
            color: flow?.border ?? cardTheme.border,
            width: AppDimens.cardBorderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                splashColor: ripple.splash,
                highlightColor: ripple.highlight,
                child: content,
              ),
      ),
    );
  }
}
