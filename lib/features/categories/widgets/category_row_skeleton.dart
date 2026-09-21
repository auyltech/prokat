import 'package:flutter/material.dart';
import 'package:prokat/features/categories/widgets/category_skeleton.dart';
import 'package:shimmer/shimmer.dart';

class CategoryRowSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const CategoryRowSkeleton({this.padding = EdgeInsets.zero, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: 5, // Fills out the width of the screen row
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[500]!.withValues(alpha: 0.2),
          highlightColor: Colors.grey[200]!.withValues(alpha: 0.2),
          child: const SizedBox(width: 140, child: CategorySkeleton()),
        ),
      ),
    );
  }
}
