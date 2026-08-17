import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_lookup.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/notifiers/chat_messages_notifier.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

export 'chat_dependencies.dart'
    show chatServiceProvider, chatSocketServiceProvider;
export 'chat_list_providers.dart' show clientChatsProvider, ownerChatsProvider;

final chatMessagesProvider =
    AsyncNotifierProvider.family<
      ChatMessagesNotifier,
      QueryState<ChatMessageModel>,
      String
    >(ChatMessagesNotifier.new);

final chatResolverProvider = FutureProvider.family<ChatModel, ChatLookup>((
  ref,
  lookup,
) async {
  final scope = ref.watch(authenticatedSessionScopeKeyProvider);
  if (scope == null) {
    throw const UnauthenticatedSessionScopeException();
  }

  ChatModel? chat;
  if (ref.exists(clientChatsProvider)) {
    chat = _findCachedChat(
      ref.read(clientChatsProvider.notifier).cachedItemsForScope(scope),
      lookup,
    );
  }
  if (chat == null && ref.exists(ownerChatsProvider)) {
    chat = _findCachedChat(
      ref.read(ownerChatsProvider.notifier).cachedItemsForScope(scope),
      lookup,
    );
  }
  if (chat != null) return chat;

  final api = ref.read(chatServiceProvider);
  final response = lookup.chatId != null
      ? await api.getChatById(lookup.chatId!)
      : await api.getChatByType(lookup.type!);

  if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
    throw const UnauthenticatedSessionScopeException();
  }

  if (!response.success || response.data == null) {
    throw Exception(response.message);
  }

  return response.data!;
});

ChatModel? _findCachedChat(Iterable<ChatModel>? chats, ChatLookup lookup) {
  if (chats == null) return null;

  for (final chat in chats) {
    if (lookup.chatId != null && chat.id == lookup.chatId) return chat;
    if (lookup.chatId == null && chat.type == lookup.type) return chat;
  }
  return null;
}
