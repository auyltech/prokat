import 'package:prokat/features/chat/models/chat_message_model.dart';

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

List<ChatMessageModel> mergeIncomingMessages(
  List<ChatMessageModel> existing,
  ChatMessageModel message,
) {
  return mergeMessages(existing, [message]);
}

List<ChatMessageModel> mergeMessages(
  List<ChatMessageModel> existing,
  List<ChatMessageModel> incoming,
) {
  final map = <String, ChatMessageModel>{};

  String key(ChatMessageModel message) {
    final clientTempId = message.clientTempId?.trim();

    if (clientTempId != null && clientTempId.isNotEmpty) {
      return "temp:$clientTempId";
    }

    return "id:${message.id}";
  }

  for (final message in existing) {
    map[key(message)] = message;
  }

  for (final message in incoming) {
    final clientTempId = message.clientTempId?.trim();

    if (clientTempId != null && clientTempId.isNotEmpty) {
      map.remove("temp:$clientTempId");
    }

    map[key(message)] = message;
  }

  final result = map.values.toList();

  result.sort(
    (a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
  );

  return result;
}
