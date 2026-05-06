import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
  }) {
    final theme = Theme.of(context);
    
    // Determine color based on type
    Color backgroundColor = theme.colorScheme.onSurface; // Default Info
    IconData icon = Icons.info_outline;

    if (isError) {
      backgroundColor = theme.colorScheme.error;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = Colors.green; // Or theme.colorScheme.primary
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Dismiss current if any
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
