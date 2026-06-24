import 'package:flutter/material.dart';

class AppSnackBar {
  // 1. Define the Global Messenger Key
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show({
    required String message,
    bool isError = false,
    bool isSuccess = false,
  }) {
    // 2. Fetch context safely from the current state tree for theming
    final context = messengerKey.currentContext;
    if (context == null) return; // Prevent crashes if UI is unmounted

    final theme = Theme.of(context);

    Color backgroundColor = theme.colorScheme.onSurface;
    IconData icon = Icons.info_outline;

    if (isError) {
      backgroundColor = theme.colorScheme.error;
      icon = Icons.error_outline;
    } else if (isSuccess) {
      backgroundColor = Colors.green;
      icon = Icons.check_circle_outline;
    }

    // 3. Target the global state directly instead of ScaffoldMessenger.of(context)
    final currentState = messengerKey.currentState;
    if (currentState != null) {
      currentState.hideCurrentSnackBar();
      currentState.showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
