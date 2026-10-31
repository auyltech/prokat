import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';

/// A reusable plate treatment for fleet cards and equipment registration forms.
/// The identifier is displayed as supplied; this widget does not validate it.
class EquipmentPlateBadge extends StatelessWidget {
  final String plateNumber;

  const EquipmentPlateBadge({super.key, required this.plateNumber});

  @override
  Widget build(BuildContext context) {
    final plate = plateNumber.trim().toUpperCase();
    if (plate.isEmpty) return const SizedBox.shrink();
    final palette = ProkatFlowPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.title, width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          plate,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
            color: palette.title,
          ),
        ),
      ),
    );
  }
}
