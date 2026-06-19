import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/providers/push_notification_service_provider.dart';
import 'package:flutter/widgets.dart';

final notificationBootstrapProvider = Provider<void>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  final push = ref.watch(pushNotificationServiceProvider);
  final navigation = ref.watch(notificationNavigationServiceProvider);
  final notificationNotifier = ref.watch(notificationProvider.notifier);

  bool started = false;
  bool lifecyclePaused = false;
  bool pushStarted = false;

  void attachSocketNotificationListener() {
    appSocket.off('notification:new');

    appSocket.on('notification:new', (payload) {
      final notification = _parseSocketNotification(payload);

      if (notification == null) return;

      notificationNotifier.handleIncomingNotification(
        notification,
        source: NotificationSource.socket,
      );
    });
  }

  Future<void> startIfReady() async {
    final startup = ref.read(appStartupProvider).routeState;
    final session = ref.read(authProvider).session;

    final isAuthenticated =
        startup == AppStartupRouteState.client ||
        startup == AppStartupRouteState.owner;

    if (!isAuthenticated || session == null) {
      return;
    }

    if (lifecyclePaused) {
      return;
    }

    if (started) {
      unawaited(navigation.flushPendingRouteIfAny());
      return;
    }

    started = true;

    // Socket live in-app notifications.
    unawaited(() async {
      try {
        await appSocket.connect();
        attachSocketNotificationListener();
      } catch (_) {
        // Best-effort: socket should not crash startup.
      }
    }());

    // Push notifications.
    if (!pushStarted) {
      pushStarted = true;

      unawaited(() async {
        try {
          await push.initialize(session: session);
        } catch (_) {}
      }());
    }

    // Initial unread count sync.
    unawaited(notificationNotifier.fetchUnreadCount());

    // Navigate pending route if any.
    unawaited(navigation.flushPendingRouteIfAny());
  }

  void stopForLogout() {
    if (!started && !pushStarted) return;

    started = false;
    pushStarted = false;

    try {
      appSocket.off('notification:new');
    } catch (_) {}

    try {
      push.dispose();
    } catch (_) {}

    notificationNotifier.clearOnLogout();
  }

  void stopForBackground() {
    if (!started) return;

    started = false;

    try {
      appSocket.off('notification:new');
    } catch (_) {}

    try {
      appSocket.disconnectSocket();
    } catch (_) {}
  }

  final lifecycleObserver = _NotificationSocketLifecycleObserver(
    onResume: () {
      lifecyclePaused = false;
      unawaited(startIfReady());
    },
    onPause: () {
      lifecyclePaused = true;
      stopForBackground();
    },
  );

  WidgetsBinding.instance.addObserver(lifecycleObserver);

  ref.listen(appStartupProvider, (previous, next) {
    if (next.routeState == AppStartupRouteState.guest ||
        next.routeState == AppStartupRouteState.otp ||
        next.routeState == AppStartupRouteState.error ||
        next.routeState == AppStartupRouteState.loading) {
      return;
    }

    unawaited(startIfReady());
  });

  ref.listen(authProvider, (previous, next) {
    final prevSession = previous?.session;
    final nextSession = next.session;

    if (prevSession != null && nextSession == null) {
      stopForLogout();

      try {
        appSocket.disconnectSocket();
      } catch (_) {}

      return;
    }

    if (nextSession != null) {
      unawaited(startIfReady());
    }
  });

  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(lifecycleObserver);

    try {
      appSocket.off('notification:new');
    } catch (_) {}

    try {
      appSocket.disconnectSocket();
    } catch (_) {}

    try {
      push.dispose();
    } catch (_) {}
  });

  unawaited(startIfReady());
});

class _NotificationSocketLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  final VoidCallback onPause;

  _NotificationSocketLifecycleObserver({
    required this.onResume,
    required this.onPause,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        onPause();
        break;
    }
  }
}

AppNotification? _parseSocketNotification(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    return AppNotification.fromJson(payload);
  }

  if (payload is Map) {
    return AppNotification.fromJson(Map<String, dynamic>.from(payload));
  }

  return null;
}
