import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/models/chat_sidebar_update.dart';

enum ChatSidebarApplyStatus { applied, notFound, skipped }

class ChatSidebarItemsApplyResult {
  final List<ChatModel> items;
  final ChatSidebarApplyStatus status;

  const ChatSidebarItemsApplyResult({
    required this.items,
    required this.status,
  });
}

ChatSidebarItemsApplyResult applyChatSidebarUpdateToItems({
  required List<ChatModel> items,
  required ChatSidebarUpdate update,
  String? currentUserId,
  bool isThreadOpen = false,
}) {
  var found = false;

  final next = items.map((chat) {
    if (chat.id != update.chatId) {
      return chat;
    }

    found = true;
    return _patchChat(
      chat: chat,
      update: update,
      currentUserId: currentUserId,
      isThreadOpen: isThreadOpen,
    );
  }).toList();

  if (!found) {
    return ChatSidebarItemsApplyResult(
      items: items,
      status: ChatSidebarApplyStatus.notFound,
    );
  }

  return ChatSidebarItemsApplyResult(
    items: _sortChats(next),
    status: ChatSidebarApplyStatus.applied,
  );
}

ChatModel _patchChat({
  required ChatModel chat,
  required ChatSidebarUpdate update,
  required String? currentUserId,
  required bool isThreadOpen,
}) {
  final incoming = update.lastMessage;
  final existing = chat.lastMessage;

  final lastMessage =
      incoming != null && _shouldReplaceLastMessage(incoming, existing)
      ? incoming
      : existing;

  final newMessagesCount = _resolveUnreadCount(
    chat: chat,
    update: update,
    incoming: incoming,
    existing: existing,
    currentUserId: currentUserId,
    isThreadOpen: isThreadOpen,
  );

  return chat.copyWith(
    lastMessage: lastMessage,
    updatedAt: lastMessage?.createdAt ?? chat.updatedAt,
    newMessagesCount: newMessagesCount,
  );
}

bool _shouldReplaceLastMessage(
  ChatMessageModel incoming,
  ChatMessageModel? existing,
) {
  if (existing == null) return true;

  final incomingAt = incoming.createdAt;
  final existingAt = existing.createdAt;
  if (incomingAt != null &&
      existingAt != null &&
      incomingAt.isBefore(existingAt)) {
    return false;
  }

  return true;
}

int? _resolveUnreadCount({
  required ChatModel chat,
  required ChatSidebarUpdate update,
  required ChatMessageModel? incoming,
  required ChatMessageModel? existing,
  required String? currentUserId,
  required bool isThreadOpen,
}) {
  if (update.unreadCount != null) {
    return update.unreadCount;
  }

  if (incoming == null || isThreadOpen) {
    return chat.newMessagesCount;
  }

  final senderId = incoming.senderId.trim();
  final selfId = currentUserId?.trim();
  if (selfId == null ||
      selfId.isEmpty ||
      senderId.isEmpty ||
      senderId == selfId) {
    return chat.newMessagesCount;
  }

  final incomingId = incoming.id.trim();
  final existingId = existing?.id.trim();
  if (incomingId.isNotEmpty && incomingId == existingId) {
    return chat.newMessagesCount;
  }

  return (chat.newMessagesCount ?? 0) + 1;
}

List<ChatModel> _sortChats(List<ChatModel> chats) {
  final sorted = List<ChatModel>.from(chats);
  sorted.sort((a, b) {
    final aDate = a.lastMessage?.createdAt ?? a.updatedAt ?? DateTime(0);
    final bDate = b.lastMessage?.createdAt ?? b.updatedAt ?? DateTime(0);
    return bDate.compareTo(aDate);
  });
  return sorted;
}
