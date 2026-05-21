import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RequestTileSkeleton extends StatelessWidget {
  const RequestTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Helper to create matching shimmer placeholders
    Widget shimmerBlock({
      required double width,
      required double height,
      double radius = 4,
    }) {
      return Shimmer.fromColors(
        baseColor: theme.hoverColor.withValues(alpha: 0.1),
        highlightColor: theme.highlightColor.withValues(alpha: 0.1),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: Renter Details & Time Status Shimmer
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Avatar Circle Mock
                  shimmerBlock(width: 36, height: 36, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Renter Name Mock
                        shimmerBlock(width: 120, height: 16, radius: 4),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Rating and Bookings Count Mock
                            shimmerBlock(width: 90, height: 12, radius: 4),
                            const SizedBox(width: 8),
                            // Remaining Time Mock
                            shimmerBlock(width: 60, height: 12, radius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge Mock
                  shimmerBlock(width: 80, height: 24, radius: 6),
                ],
              ),

              const SizedBox(height: 14),

              // SECTION 2: Equipment Container Card Shimmer
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Equipment Image Mock (16:9 ratio placeholder matching width 80)
                    shimmerBlock(width: 80, height: 45, radius: 6),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Equipment Title Mock
                          shimmerBlock(width: 150, height: 14, radius: 4),
                          const SizedBox(height: 6),
                          // Plate Number Mock
                          shimmerBlock(width: 80, height: 12, radius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // SECTION 3: Logistics (Two Column Info Mock)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerBlock(width: 90, height: 10, radius: 2),
                        const SizedBox(height: 6),
                        shimmerBlock(width: 110, height: 12, radius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date & Time Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerBlock(width: 70, height: 10, radius: 2),
                        const SizedBox(height: 6),
                        shimmerBlock(width: 130, height: 12, radius: 4),
                      ],
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, thickness: 0.5),
              ),

              // SECTION 4: Total Earnings & Three Action Buttons Shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Financial Section Mock
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmerBlock(width: 80, height: 10, radius: 2),
                      const SizedBox(height: 4),
                      shimmerBlock(width: 70, height: 18, radius: 4),
                    ],
                  ),
                  // Action Row Buttons Block Mock
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cancel Icon Mock
                      shimmerBlock(width: 44, height: 44, radius: 8),
                      const SizedBox(width: 8),
                      // Chat Icon Mock
                      shimmerBlock(width: 44, height: 44, radius: 8),
                      const SizedBox(width: 12),
                      // Primary Text Action Mock (Accept / Status Button width)
                      shimmerBlock(width: 100, height: 44, radius: 8),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
