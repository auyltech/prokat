import 'package:prokat/features/chat/state/chat_message_model.dart';

bool withinThirtySeconds(DateTime? first, DateTime? second) {
  if (first == null || second == null) return false;

  return first.difference(second).inSeconds.abs() <= 30;
}

List<ChatMessageModel> sortMessages(List<ChatMessageModel> messages) {
  final sorted = List<ChatMessageModel>.from(messages);

  sorted.sort((a, b) {
    final aDate = a.createdAt ?? DateTime(1970);
    final bDate = b.createdAt ?? DateTime(1970);

    return bDate.compareTo(aDate);
  });

  return sorted;
}

List<ChatMessageModel> mergeMessages(
  List<ChatMessageModel> existing,
  ChatMessageModel incoming,
) {
  final updated = List<ChatMessageModel>.from(existing);

  final cleanIncoming = incoming.copyWith(
    isPending: false,
    isFailed: false,
  );

  final exactIndex = updated.indexWhere(
    (message) => message.id.isNotEmpty && message.id == incoming.id,
  );

  if (exactIndex != -1) {
    updated[exactIndex] = cleanIncoming;
    return sortMessages(updated);
  }

  final tempIndex = updated.indexWhere(
    (message) =>
        (message.clientTempId ?? '').trim().isNotEmpty &&
        message.clientTempId == incoming.clientTempId,
  );

  if (tempIndex != -1) {
    updated[tempIndex] = cleanIncoming;
    return sortMessages(updated);
  }

  final fallbackPendingIndex = updated.indexWhere(
    (message) =>
        message.isPending &&
        message.senderId == incoming.senderId &&
        message.content.trim() == incoming.content.trim() &&
        withinThirtySeconds(message.createdAt, incoming.createdAt),
  );

  if (fallbackPendingIndex != -1) {
    updated[fallbackPendingIndex] = cleanIncoming;
    return sortMessages(updated);
  }

  updated.insert(0, cleanIncoming);
  return sortMessages(updated);
}