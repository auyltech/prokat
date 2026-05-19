import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';
import 'package:prokat/features/notifications/services/notification_navigation_service.dart';
import 'package:prokat/features/notifications/services/push_notification_service.dart';

final notificationLocalStorageProvider = Provider<NotificationLocalStorage>((ref) {
  return NotificationLocalStorage();
});

final notificationNavigationServiceProvider =
    Provider<NotificationNavigationService>((ref) {
  final storage = ref.watch(notificationLocalStorageProvider);
  return NotificationNavigationService(ref, storage);
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final api = ref.watch(notificationApiServiceProvider);
  final storage = ref.watch(notificationLocalStorageProvider);
  final navigation = ref.watch(notificationNavigationServiceProvider);
  final notifier = ref.watch(notificationProvider.notifier);

  return PushNotificationService(
    messaging: FirebaseMessaging.instance,
    localNotifications: FlutterLocalNotificationsPlugin(),
    api: api,
    storage: storage,
    navigation: navigation,
    onIncoming: (AppNotification notification) {
      notifier.handleIncomingNotification(
        notification,
        source: NotificationSource.fcm,
      );
    },
    shouldSuppressDisplay: (id) {
      final recentIds = ref.read(notificationProvider).recentIds;
      return recentIds.containsKey(id);
    },
  );
});

final notificationBootstrapProvider = Provider<void>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  final push = ref.watch(pushNotificationServiceProvider);
  final navigation = ref.watch(notificationNavigationServiceProvider);
  final notificationNotifier = ref.watch(notificationProvider.notifier);

  bool started = false;

  Future<void> startIfReady() async {
    final startup = ref.read(appStartupProvider).routeState;
    final session = ref.read(authProvider).session;

    final isAuthenticated =
        startup == AppStartupRouteState.client || startup == AppStartupRouteState.owner;

    if (!isAuthenticated || session == null) {
      return;
    }

    if (started) {
      // Still flush pending deep links if any.
      unawaited(navigation.flushPendingRouteIfAny());
      return;
    }
    started = true;

    // Socket (best-effort)
    unawaited(() async {
      try {
        await appSocket.connect(token: session.sessionToken);
        appSocket.on('notification:new', (payload) {
          final notification = _parseSocketNotification(payload);
          if (notification == null) return;
          notificationNotifier.handleIncomingNotification(
            notification,
            source: NotificationSource.socket,
          );
        });
      } catch (_) {
        // Best-effort: socket should not crash startup.
      }
    }());

    // Push (best-effort)
    unawaited(() async {
      try {
        await push.initialize(session: session);
      } catch (_) {}
    }());

    // Initial unread count sync (best-effort)
    unawaited(notificationNotifier.fetchUnreadCount());

    // Navigate pending route if any
    unawaited(navigation.flushPendingRouteIfAny());
  }

  void stop() {
    if (!started) return;
    started = false;

    try {
      appSocket.off('notification:new');
    } catch (_) {}

    try {
      push.dispose();
    } catch (_) {}

    notificationNotifier.clearOnLogout();
  }

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
      stop();
      try {
        appSocket.disconnect();
      } catch (_) {}
      return;
    }

    if (nextSession != null) {
      unawaited(startIfReady());
    }
  });

  // Kick off once in case state is already ready.
  unawaited(startIfReady());
});

AppNotification? _parseSocketNotification(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    return AppNotification.fromJson(payload);
  }
  if (payload is Map) {
    return AppNotification.fromJson(Map<String, dynamic>.from(payload));
  }
  return null;
}
