import 'package:flutter/material.dart';
import 'package:prokat/features/equipment/widgets/list/single_equipment_skeleton.dart';
import 'package:shimmer/shimmer.dart';

class EquipmentListSkeleton extends StatelessWidget {
  final double height;

  const EquipmentListSkeleton({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 0),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[500]!.withValues(alpha: 0.2),
        highlightColor: Colors.grey[200]!.withValues(alpha: 0.2),
        child: SingleEquipmentCardSkeleton(height: height),
      ),
    );
  }
}
