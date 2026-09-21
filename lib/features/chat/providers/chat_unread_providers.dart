import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';

int _sumUnread(QueryState<ChatModel>? state) {
  if (state == null) return 0;
  var total = 0;
  for (final chat in state.items) {
    final unread = chat.newMessagesCount ?? 0;
    if (unread > 0) total += unread;
  }
  return total;
}

/// Unread messages across the client's active threads. Live: the chat list state
/// is patched by socket sidebar updates and reset to 0 when a thread is read.
final clientChatUnreadCountProvider = Provider<int>((ref) {
  return _sumUnread(ref.watch(clientChatsProvider).valueOrNull);
});

/// Unread messages across the owner's active threads.
final ownerChatUnreadCountProvider = Provider<int>((ref) {
  return _sumUnread(ref.watch(ownerChatsProvider).valueOrNull);
});
