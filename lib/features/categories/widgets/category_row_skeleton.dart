import 'package:flutter/material.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/widgets/category_skeleton.dart';
import 'package:shimmer/shimmer.dart';

class CategoryRowSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double tileWidth;
  final double tileExtent;

  const CategoryRowSkeleton({
    this.padding = EdgeInsets.zero,
    this.tileWidth = 140,
    double? tileExtent,
    super.key,
  }) : tileExtent =
           tileExtent ??
           tileWidth / CategoryCard.imageAspectRatio +
               CategoryCard.imageLabelGap +
               CategoryCard.labelHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tileExtent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[500]!.withValues(alpha: 0.2),
          highlightColor: Colors.grey[200]!.withValues(alpha: 0.2),
          child: SizedBox(
            width: tileWidth,
            child: CategorySkeleton(tileWidth: tileWidth),
          ),
        ),
      ),
    );
  }
}
