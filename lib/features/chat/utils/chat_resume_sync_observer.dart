import 'package:flutter/widgets.dart';

/// Reloads chat state after the app returns from a real background.
///
/// [AppLifecycleState.inactive] is ignored so the keyboard / system gestures
/// do not trigger a refetch.
class ChatResumeSyncObserver extends WidgetsBindingObserver {
  ChatResumeSyncObserver({required this.onResumeFromBackground});

  final VoidCallback onResumeFromBackground;

  bool leftForeground = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        leftForeground = true;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        if (!leftForeground) return;
        leftForeground = false;
        onResumeFromBackground();
    }
  }
}
