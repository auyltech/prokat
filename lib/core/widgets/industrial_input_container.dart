import 'package:flutter/material.dart';

class IndustrialInputContainer extends StatelessWidget {
  final String label;
  final Widget child;

  const IndustrialInputContainer({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceBright, // Inset Panel
        borderRadius: BorderRadius.circular(16), // Small Item Radius
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ), // Rim Light
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),

          const SizedBox(height: 4),

          child,
        ],
      ),
    );
  }
}
