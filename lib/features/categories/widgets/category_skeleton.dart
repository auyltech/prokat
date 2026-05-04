import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics:
            const NeverScrollableScrollPhysics(), // Prevent scrolling while loading
        itemCount: 4, // Show 4 placeholders
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 280, // Matches your ListTile width roughly
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Leading Image Placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                // Text Placeholders
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 14, color: Colors.black),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 10, color: Colors.black),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black),
              ],
            ),
          );
        },
      ),
    );
  }
}
