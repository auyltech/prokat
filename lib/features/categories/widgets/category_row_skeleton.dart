import 'package:flutter/material.dart';
import 'package:prokat/features/categories/widgets/category_skeleton.dart';
import 'package:shimmer/shimmer.dart';

class CategoryRowSkeleton extends StatelessWidget {
  const CategoryRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90, // Wraps the visual bounds of the service items
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: 5, // Fills out the width of the screen row
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: const CategorySkeleton(),
        ),
      ),
    );
  }
}
