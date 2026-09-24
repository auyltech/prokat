import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_group.dart';
import 'package:prokat/features/notifications/models/notification_type.dart';

AppNotification item(
  String id,
  String chatId, {
  NotificationType type = NotificationType.chatMessageCreated,
  bool read = false,
}) => AppNotification(
  id: id,
  type: type,
  category: 'CHAT',
  title: 'Чат',
  body: id,
  data: {'chatId': chatId},
  readAt: read ? DateTime(2026) : null,
);

void main() {
  test('messages group by chat while order events remain separate', () {
    final groups = groupNotifications([
      item('new', 'a'),
      item('other', 'b'),
      item('old', 'a', read: true),
      item('new', 'a'),
      item('order', 'a', type: NotificationType.bookingConfirmed),
    ]);
    expect(groups, hasLength(3));
    expect(groups.first.latest.id, 'new');
    expect(groups.first.items, hasLength(2));
    expect(groups.first.unreadCount, 1);
    expect(groups.last.isChat, false);
  });
}
