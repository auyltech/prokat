import 'package:flutter/material.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';

class CategorySkeleton extends StatelessWidget {
  final double tileWidth;

  const CategorySkeleton({this.tileWidth = 140, super.key});

  @override
  Widget build(BuildContext context) {
    final imageHeight = tileWidth / CategoryCard.imageAspectRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tileWidth,
          height: imageHeight,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: CategoryCard.imageLabelGap),
        Container(
          width: tileWidth,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
