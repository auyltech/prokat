import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RequestTileSkeleton extends StatelessWidget {
  const RequestTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Helper to create the gray placeholders
    Widget shimmerBlock({
      required double width,
      required double height,
      double radius = 4,
    }) {
      return Shimmer.fromColors(
        baseColor: theme.hoverColor,
        highlightColor: theme.highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.5,
            ), // Reduced alpha for skeleton feel
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- HEADER ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mock Image
                shimmerBlock(width: 60, height: 60, radius: 12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge Mock
                      shimmerBlock(width: 70, height: 18, radius: 12),
                      const SizedBox(height: 8),
                      // Title Mock
                      shimmerBlock(width: 140, height: 20),
                      const SizedBox(height: 6),
                      // Location Mock
                      shimmerBlock(width: 100, height: 14),
                    ],
                  ),
                ),
                // Time Mock
                shimmerBlock(width: 40, height: 12),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, thickness: 0.5),
            ),

            /// --- FOOTER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmerBlock(width: 60, height: 12),
                    const SizedBox(height: 6),
                    shimmerBlock(width: 90, height: 24),
                  ],
                ),
                // Button Mock
                shimmerBlock(width: 110, height: 44, radius: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
