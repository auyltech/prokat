import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/services/push_notification_service.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      if (notificationRefreshesOwnerRequestFeed(notification.type)) {
        refreshOwnerRequestFeed(ref);
      }
      if (notificationRefreshesOwnerOrderBadge(notification.type)) {
        refreshOwnerOrderBadge(ref);
      }
    },
    currentLocale: () => ref.read(localeProvider).languageCode,
    shouldSuppressDisplay: (id) => ref
        .read(notificationProvider)
        .items
        .any((item) => item.id == id && item.isRead),
  );
});
