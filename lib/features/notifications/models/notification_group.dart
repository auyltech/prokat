import 'app_notification.dart';
import 'notification_type.dart';

class NotificationGroup {
  final List<AppNotification> items;
  const NotificationGroup(this.items);

  AppNotification get latest => items.first;
  int get unreadCount => items.where((item) => item.isUnread).length;
  bool get isChat =>
      latest.type == NotificationType.chatMessageCreated &&
      latest.chatId != null;
}

List<NotificationGroup> groupNotifications(List<AppNotification> items) {
  final groups = <String, List<AppNotification>>{};
  final seen = <String>{};
  for (final item in items) {
    if (!seen.add(item.id)) continue;
    final key =
        item.type == NotificationType.chatMessageCreated && item.chatId != null
        ? 'chat:${item.audience ?? ""}:${item.chatId}'
        : 'notification:${item.id}';
    (groups[key] ??= []).add(item);
  }
  return groups.values
      .map((items) => NotificationGroup(List.unmodifiable(items)))
      .toList(growable: false);
}
