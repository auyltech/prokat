import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_input_field_style.dart';

class AppInputFieldBox extends StatelessWidget {
  final bool isFocused;
  final bool hasError;
  final Color backgroundColor;
  final double? height;
  final double? minHeight;
  final Widget child;

  const AppInputFieldBox({
    required this.isFocused,
    required this.hasError,
    required this.backgroundColor,
    required this.child,
    this.height,
    this.minHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.colors.textField;
    final outerRadius = AppInputFieldStyle.borderRadius;
    final showFocusChrome = isFocused && !hasError;
    final strokeWidth = hasError
        ? AppDimens.inputBorderWidthError
        : AppDimens.inputBorderWidth;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: outerRadius,
        boxShadow: showFocusChrome
            ? [BoxShadow(color: theme.focusHalo, spreadRadius: 2)]
            : null,
      ),
      child: CustomPaint(
        foregroundPainter: showFocusChrome
            ? _InsideGradientBorderPainter(
                gradient: theme.focusGradient,
                strokeWidth: AppDimens.inputBorderWidth,
                radius: AppDimens.r10$base,
              )
            : _InsideSolidBorderPainter(
                color: hasError ? theme.borderError : theme.border,
                strokeWidth: strokeWidth,
                radius: AppDimens.r10$base,
              ),
        child: SizedBox(
          height: height,
          child: height != null
              ? Center(child: child)
              : ConstrainedBox(
                  constraints: minHeight == null
                      ? const BoxConstraints()
                      : BoxConstraints(minHeight: minHeight!),
                  child: child,
                ),
        ),
      ),
    );
  }
}

final class _InsideSolidBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _InsideSolidBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _insideBorderPath(size: size, strokeWidth: strokeWidth, radius: radius),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _InsideSolidBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

final class _InsideGradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;
  final double radius;

  const _InsideGradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawPath(
      _insideBorderPath(size: size, strokeWidth: strokeWidth, radius: radius),
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _InsideGradientBorderPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}

Path _insideBorderPath({
  required Size size,
  required double strokeWidth,
  required double radius,
}) {
  final outerRect = Offset.zero & size;
  final outer = RRect.fromRectAndRadius(outerRect, Radius.circular(radius));
  final inner = RRect.fromRectAndRadius(
    outerRect.deflate(strokeWidth),
    Radius.circular(math.max(0, radius - strokeWidth)),
  );

  return Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(outer)
    ..addRRect(inner);
}
