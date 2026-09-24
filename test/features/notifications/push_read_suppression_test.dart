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

class _Local extends Fake implements FlutterLocalNotificationsPlugin {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    return super.noSuchMethod(invocation);
  }
}

class _Api extends Fake implements NotificationApiService {}

class _Storage extends Fake implements NotificationLocalStorage {}

class _Navigation extends Fake implements NotificationNavigationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  for (final locallyRead in [false, true]) {
    test(
      'suppress ${locallyRead ? "locally" : "server"} read notification before display',
      () async {
        var checks = 0;
        final local = _Local();
        final service = PushNotificationService(
          messaging: _Messaging(),
          localNotifications: local,
          api: _Api(),
          storage: _Storage(),
          navigation: _Navigation(),
          onIncoming: (_) {},
          shouldSuppressDisplay: (_) {
            checks++;
            return locallyRead;
          },
        );
        final notification = AppNotification.fromJson({
          'id': 'already-read',
          'type': 'REQUEST_CREATED',
          'category': 'REQUEST',
          'title': 'New request',
          'body': '',
          'data': <String, dynamic>{},
          if (!locallyRead) 'readAt': '2026-09-21T12:00:00Z',
        });
        expect(notification.type, isA<NotificationType>());
        // A call into any platform fake would fail. Both socket and FCM share
        // presentIncoming, including a late unread payload after local reading.
        await service.presentIncoming(notification);
        expect(checks, locallyRead ? 1 : 0);
        expect(local.calls, 0);
      },
    );
  }
}
