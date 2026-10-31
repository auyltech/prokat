import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';
import 'package:prokat/features/notifications/services/notification_local_storage.dart';
import 'package:prokat/features/notifications/services/notification_navigation_service.dart';
import 'package:prokat/features/notifications/services/push_notification_service.dart';

class _Messaging extends Fake implements FirebaseMessaging {}

class _Api extends Fake implements NotificationApiService {}

class _Storage extends Fake implements NotificationLocalStorage {}

class _Navigation extends Fake implements NotificationNavigationService {}

class _Local extends Fake implements FlutterLocalNotificationsPlugin {
  int shown = 0;
  NotificationDetails? details;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #initialize) return Future<bool>.value(true);
    if (invocation.memberName == #resolvePlatformSpecificImplementation) {
      return null;
    }
    if (invocation.memberName == #show) {
      shown++;
      details =
          invocation.namedArguments[#notificationDetails]
              as NotificationDetails;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('foreground FCM uses the system tray once with sound and vibration, not an overlay', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    var overlayCalls = 0;
    final local = _Local();
    final service = PushNotificationService(
      messaging: _Messaging(),
      localNotifications: local,
      api: _Api(),
      storage: _Storage(),
      navigation: _Navigation(),
      onIncoming: (_) {},
      presentForeground: (_) {
        overlayCalls++;
        return true;
      },
    );
    const event = AppNotification(
      id: 'qa-fcm',
      type: NotificationType.bookingCreated,
      category: 'BOOKING',
      title: 'Order',
      body: 'New order',
      data: {},
    );
    await service.presentIncoming(event);
    await service.presentIncoming(event);
    expect(local.shown, 1);
    expect(overlayCalls, 0);
    expect(local.details?.android?.playSound, true);
    expect(local.details?.android?.enableVibration, true);
  });
}
