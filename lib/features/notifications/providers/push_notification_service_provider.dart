import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/services/push_notification_service.dart';
import 'package:riverpod/riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
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
