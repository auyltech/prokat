import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class EquipmentSkeleton extends StatelessWidget {
  const EquipmentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Container(
              height: 100, // Match ClientEquipmentCard height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 140, height: 16, color: Colors.black),
                        const SizedBox(height: 8),
                        Container(width: 80, height: 12, color: Colors.black),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        childCount: 5, // Show a few placeholders
      ),
    );
  }
}
