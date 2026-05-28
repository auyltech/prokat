import 'package:flutter/material.dart';

class SingleEquipmentCardSkeleton extends StatelessWidget {
  const SingleEquipmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Image / Main Banner Block
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Title Line
                Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.black,
                ),
                const SizedBox(height: 8),
                // 3. Subtitle / Rating Line
                Container(
                  width: 120,
                  height: 14,
                  color: Colors.black,
                ),
                const SizedBox(height: 16),
                // 4. Badges / Specifications Row
                Row(
                  children: [
                    Container(width: 90, height: 24, color: Colors.black),
                    const SizedBox(width: 8),
                    Container(width: 90, height: 24, color: Colors.black),
                  ],
                ),
                const SizedBox(height: 16),
                // 5. Reserve Now Button Block
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
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
