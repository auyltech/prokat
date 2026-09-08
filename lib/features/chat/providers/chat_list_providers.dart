import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/notifiers/client_chats_notifier.dart';
import 'package:prokat/features/chat/notifiers/owner_chats_notifier.dart';

final clientChatsByFilterProvider =
    AsyncNotifierProvider.family<
      ClientChatsNotifier,
      QueryState<ChatModel>,
      ChatListFilter
    >(ClientChatsNotifier.new);

final ownerChatsByFilterProvider =
    AsyncNotifierProvider.family<
      OwnerChatsNotifier,
      QueryState<ChatModel>,
      ChatListFilter
    >(OwnerChatsNotifier.new);

final clientChatsProvider = clientChatsByFilterProvider(ChatListFilter.active);

final ownerChatsProvider = ownerChatsByFilterProvider(ChatListFilter.active);

final clientArchivedChatsProvider = clientChatsByFilterProvider(
  ChatListFilter.archived,
);

final ownerArchivedChatsProvider = ownerChatsByFilterProvider(
  ChatListFilter.archived,
);
