import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';
import 'package:prokat/features/notifications/services/notification_notifier.dart';

AppNotification notification({bool read = false}) => AppNotification(
  id: 'same-id',
  type: NotificationType.offerCreated,
  category: 'OFFER',
  title: 'Предложение',
  body: '',
  data: const {},
  readAt: read ? DateTime(2026) : null,
);

class FakeApi extends NotificationApiService {
  FakeApi() : super(Dio());
  @override
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async => [notification(read: true)];
  @override
  Future<int> getUnreadCount() async => 0;
}

void main() {
  test(
    'late push does not unread a notification already loaded as read',
    () async {
      final notifier = NotificationNotifier(FakeApi());
      addTearDown(notifier.dispose);
      await notifier.loadInitial();
      notifier.handleIncomingNotification(
        notification(),
        source: NotificationSource.fcm,
      );
      expect(notifier.state.unreadCount, 0);
      expect(notifier.state.items.single.isRead, true);
    },
  );
  test('socket and push for the same id increment the count only once', () {
    final notifier = NotificationNotifier(FakeApi());
    addTearDown(notifier.dispose);
    notifier.handleIncomingNotification(
      notification(),
      source: NotificationSource.socket,
    );
    notifier.handleIncomingNotification(
      notification(),
      source: NotificationSource.fcm,
    );
    expect(notifier.state.unreadCount, 1);
    expect(notifier.state.items, hasLength(1));
  });
}
