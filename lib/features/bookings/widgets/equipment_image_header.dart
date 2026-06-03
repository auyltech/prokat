import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';

class EquipmentImageHeader extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final Widget? overlay;

  const EquipmentImageHeader({
    super.key,
    required this.imageUrl,
    this.height = 220,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        children: [
          /// Image
          SizedBox(
            height: height,
            width: double.infinity,
            child: OptimizedNetworkImage(
              imageUrl: imageUrl ?? "",
              fit: BoxFit.cover,
              fallbackIcon: Icons.image_not_supported,
              backgroundColor: Colors.grey[300],
            ),
          ),

          /// Optional gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black26, Colors.transparent],
                ),
              ),
            ),
          ),

          /// Optional overlay widget (title, actions, etc.)
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );
  }
}
