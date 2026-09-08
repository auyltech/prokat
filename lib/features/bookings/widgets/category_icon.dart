import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String category;
  const CategoryIcon({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Logic to pick icon based on category string
    IconData iconData;
    switch (category.toUpperCase()) {
      case 'EXCAVATION':
        iconData = Icons.agriculture_rounded;
        break;
      case 'LOGISTICS':
        iconData = Icons.local_shipping_rounded;
        break;
      case 'LIFTING':
        iconData = Icons.precision_manufacturing_rounded;
        break;
      default:
        iconData = Icons.construction_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3), // Deep recessed look
        borderRadius: BorderRadius.circular(14), // Matches small item radius
        border: Border.all(
          color: const Color(0xFF4E73DF)
              .withValues(alpha: 0.2), // Faint blue glow
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        color: const Color(0xFF4E73DF), // Industrial Blue
        size: 24,
      ),
    );
  }
}
