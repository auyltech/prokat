import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';

class PageDotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  final bool elevated;

  const PageDotsIndicator({
    super.key,
    required this.count,
    required this.index,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final active = elevated
        ? colorScheme.onSurface.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);
    final inactive = elevated
        ? colorScheme.onSurface.withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.4);

    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: AppDimens.s04$xs - 1),
          width: isActive ? 10 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(AppDimens.r999$full),
          ),
        );
      }),
    );

    if (!elevated) {
      return Center(child: dots);
    }

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppDimens.r999$full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.s08$sm,
            vertical: AppDimens.s04$xs,
          ),
          child: dots,
        ),
      ),
    );
  }
}
