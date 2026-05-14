import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          // padding: const EdgeInsets.symmetric(vertical: 8),
          // decoration: BoxDecoration(
          //   color: color.withValues(alpha: 0.15),
          //   borderRadius: BorderRadius.circular(10),
          //   border: Border.all(color: color.withValues(alpha: 0.2)),
          // ),
          child: Icon(icon, size: 32, color: color),
        ),
      ),
    );
  }
}
