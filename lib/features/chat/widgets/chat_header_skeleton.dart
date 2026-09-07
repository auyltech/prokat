import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatHeaderSkeleton extends StatelessWidget {
  const ChatHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[500]!.withValues(alpha: 0.2),
      highlightColor: Colors.grey[200]!.withValues(alpha: 0.2),
      child: Row(
        children: [
          // 1. Avatar Circle
          const CircleAvatar(radius: 22),

          const SizedBox(width: 12),

          // 2. Text Lines Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name placeholder
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(height: 6),

                // Timestamp placeholder
                Container(
                  width: 90,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
