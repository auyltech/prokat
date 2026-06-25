import 'package:flutter/material.dart';

class SingleEquipmentCardSkeleton extends StatelessWidget {
  final double height;

  const SingleEquipmentCardSkeleton({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
    );
  }
}
