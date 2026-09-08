import 'package:prokat/features/chat/models/chat_message_model.dart';

/// Offer cards carry a full offer DTO in [ChatMessageModel.meta] (`id` present).
/// Losing-tender EVENT rows reuse `service: OFFER` but only have `offerId` /
/// `reason: NOT_SELECTED` — those must render as text, not as an offer card.
bool isOfferCardMessage(ChatMessageModel message) {
  if (message.service != 'OFFER') return false;

  final meta = message.meta;
  if (meta == null) return false;
  if (meta['reason']?.toString() == 'NOT_SELECTED') return false;

  final id = meta['id']?.toString().trim() ?? '';
  return id.isNotEmpty;
}

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
  String? normalized(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }

  String? tempIdOf(ChatMessageModel message) {
    return normalized(message.clientTempId);
  }

  String? serverIdOf(ChatMessageModel message) {
    // Pending and failed messages are local optimistic messages.
    // Their `id` may currently be the clientTempId, not a backend ID.
    if (message.isPending || message.isFailed) {
      return null;
    }

    return normalized(message.id);
  }

  bool hasSameIdentity(ChatMessageModel first, ChatMessageModel second) {
    final firstServerId = serverIdOf(first);
    final secondServerId = serverIdOf(second);

    // This handles confirmed messages, including legacy messages
    // that do not have a clientTempId.
    if (firstServerId != null &&
        secondServerId != null &&
        firstServerId == secondServerId) {
      return true;
    }

    final firstTempId = tempIdOf(first);
    final secondTempId = tempIdOf(second);

    // This reconciles an optimistic message with its confirmation.
    return firstTempId != null &&
        secondTempId != null &&
        firstTempId == secondTempId;
  }

  ChatMessageModel preferredMessage(
    ChatMessageModel current,
    ChatMessageModel candidate,
  ) {
    final currentIsConfirmed = serverIdOf(current) != null;
    final candidateIsConfirmed = serverIdOf(candidate) != null;

    // Never replace a confirmed message with a pending or failed copy.
    final preferred = currentIsConfirmed && !candidateIsConfirmed
        ? current
        : candidate;

    // Preserve the clientTempId if one representation does not contain it.
    final clientTempId = tempIdOf(candidate) ?? tempIdOf(current);

    return preferred.copyWith(clientTempId: clientTempId);
  }

  final result = <ChatMessageModel>[];

  void addMessage(ChatMessageModel message) {
    var resolved = message;

    // Repeat because resolving by server ID may expose a clientTempId
    // that matches another optimistic copy already in the list.
    while (true) {
      final matchingIndexes = <int>[];

      for (var index = 0; index < result.length; index++) {
        if (hasSameIdentity(result[index], resolved)) {
          matchingIndexes.add(index);
        }
      }

      if (matchingIndexes.isEmpty) {
        break;
      }

      for (final index in matchingIndexes) {
        resolved = preferredMessage(result[index], resolved);
      }

      // Remove backwards so list indexes remain valid.
      for (final index in matchingIndexes.reversed) {
        result.removeAt(index);
      }
    }

    result.add(resolved);
  }

  for (final message in existing) {
    addMessage(message);
  }

  for (final message in incoming) {
    addMessage(message);
  }

  return sortMessages(result);
}
