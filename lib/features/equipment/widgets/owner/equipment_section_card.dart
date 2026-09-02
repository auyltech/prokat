import 'package:flutter/material.dart';

class EquipmentSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onAction; // Renamed from onEdit for flexibility
  final IconData actionIcon; // Custom icon (edit or add)
  final bool isActionEnabled; // Controls the button state

  const EquipmentSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.onAction,
    this.actionIcon = Icons.edit_rounded, // Defaults to edit
    this.isActionEnabled = true, // Defaults to enabled
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                // Adaptive Action Button
                IconButton.filledTonal(
                  icon: Icon(actionIcon, size: 18),
                  // Button is visually disabled if isActionEnabled is false or onAction is null
                  onPressed: isActionEnabled ? onAction : null,
                  style: IconButton.styleFrom(
                    disabledBackgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceDim
                        .withAlpha(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
