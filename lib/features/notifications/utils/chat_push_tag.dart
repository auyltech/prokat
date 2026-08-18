const chatPushTagPrefix = 'prokat.chat.';

/// Android FCM / local notification tag. Keep in sync with
/// `prokat-backend/src/modules/notifications/chat-push-tag.ts`.
String chatPushTag(String chatId) => '$chatPushTagPrefix${chatId.trim()}';

bool displayedNotificationMatchesChat({
  required String chatId,
  String? tag,
  String? payload,
}) {
  final expected = chatPushTag(chatId);
  if ((tag ?? '').trim() == expected) return true;

  final payloadText = payload ?? '';
  return payloadText.contains(chatId);
}
