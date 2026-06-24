import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // 1. Added import

class OwnerBookingSkeleton extends StatelessWidget {
  const OwnerBookingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Adjusted color alphas slightly for better shimmer visibility contrast
    final base = colors.onSurface.withValues(alpha: 0.1);
    final highlight = colors.onSurface.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      // 2. Wrap the skeleton layout with Shimmer.fromColors
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(
          milliseconds: 1500,
        ), // Control speed of the animation
        child: Column(
          children: [
            /// HEADER
            Row(
              children: [
                _SkeletonBox(
                  size: 40,
                  radius: 12,
                  base: base,
                  highlight: highlight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonLine(
                        width: 80,
                        base: base,
                        highlight: highlight,
                      ),
                      const SizedBox(height: 6),
                      _SkeletonLine(
                        width: 140,
                        height: 14,
                        base: base,
                        highlight: highlight,
                      ),
                    ],
                  ),
                ),
                _SkeletonBox(
                  size: 60,
                  height: 20,
                  radius: 10,
                  base: base,
                  highlight: highlight,
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// TITLE
            _SkeletonLine(
              width: double.infinity,
              height: 14,
              base: base,
              highlight: highlight,
            ),

            const SizedBox(height: 16),

            /// META ROWS
            _SkeletonMetaRow(base: base, highlight: highlight),
            const SizedBox(height: 12),
            _SkeletonMetaRow(base: base, highlight: highlight),

            const SizedBox(height: 20),

            /// FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 100, base: base, highlight: highlight),
                    const SizedBox(height: 6),
                    _SkeletonLine(
                      width: 80,
                      height: 16,
                      base: base,
                      highlight: highlight,
                    ),
                  ],
                ),
                _SkeletonBox(
                  size: 20,
                  radius: 6,
                  base: base,
                  highlight: highlight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double size;
  final double? height;
  final double radius;
  final Color base;
  final Color highlight;

  const _SkeletonBox({
    required this.size,
    this.height,
    required this.radius,
    required this.base,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        color: Colors
            .white, // Colors here must be solid for the shimmer overlay mask to clip onto them properly
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final Color base;
  final Color highlight;

  const _SkeletonLine({
    required this.width,
    this.height = 10,
    required this.base,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color:
            Colors.white, // Changed to solid color so shimmer masks correctly
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SkeletonMetaRow extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _SkeletonMetaRow({required this.base, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SkeletonBox(size: 16, radius: 6, base: base, highlight: highlight),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonLine(width: 80, base: base, highlight: highlight),
            const SizedBox(height: 4),
            _SkeletonLine(
              width: 140,
              height: 12,
              base: base,
              highlight: highlight,
            ),
          ],
        ),
      ],
    );
  }
}
