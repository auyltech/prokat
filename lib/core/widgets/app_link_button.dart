import 'package:flutter/material.dart';

class AppLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AppLinkButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
