import 'package:flutter/material.dart';
import 'package:prokat/features/equipment/widgets/list/single_equipment_skeleton.dart';
import 'package:shimmer/shimmer.dart';

class EquipmentListSkeleton extends StatelessWidget {
  const EquipmentListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 3, // Shows a realistic number of large cards
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: const SingleEquipmentCardSkeleton(),
      ),
    );
  }
}
