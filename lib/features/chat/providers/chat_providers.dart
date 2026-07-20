import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_lookup.dart';
import 'package:prokat/features/chat/notifiers/chat_messages_notifier.dart';
import 'package:prokat/features/chat/notifiers/chat_notifier.dart';
import 'package:prokat/features/chat/notifiers/client_chats_notifier.dart';
import 'package:prokat/features/chat/notifiers/owner_chats_notifier.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/service/chat_service.dart';
import 'package:prokat/features/chat/service/chat_socket_service.dart';
import 'package:riverpod/riverpod.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatService(apiClient);
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final appSocket = ref.watch(appSocketProvider);
  return ChatSocketService(appSocket);
});

final clientChatsProvider =
    AsyncNotifierProvider<ClientChatsNotifier, QueryState<ChatModel>>(
      ClientChatsNotifier.new,
    );

final ownerChatsProvider =
    AsyncNotifierProvider<OwnerChatsNotifier, QueryState<ChatModel>>(
      OwnerChatsNotifier.new,
    );

final chatProvider =
    AsyncNotifierProvider.family<ChatNotifier, ChatModel, String>(
      ChatNotifier.new,
    );

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
  final api = ref.read(chatServiceProvider);

  ChatModel? chat;

  // 1. Search client chats
  final clientChats = ref.read(clientChatsProvider).valueOrNull?.items;

  if (clientChats != null) {
    if (lookup.chatId != null) {
      chat = clientChats.where((c) => c.id == lookup.chatId).firstOrNull;
    } else {
      chat = clientChats.where((c) => c.type == lookup.type).firstOrNull;
    }
  }

  // 2. Search owner chats
  if (chat == null) {
    final ownerChats = ref.read(ownerChatsProvider).valueOrNull?.items;

    if (ownerChats != null) {
      if (lookup.chatId != null) {
        chat = ownerChats.where((c) => c.id == lookup.chatId).firstOrNull;
      } else {
        chat = ownerChats.where((c) => c.type == lookup.type).firstOrNull;
      }
    }
  }

  // 3. Already loaded
  if (chat != null) {
    return chat;
  }

  // 4. Fetch
  final response = lookup.chatId != null
      ? await api.getChatById(lookup.chatId!)
      : await api.getChatByType(lookup.type!);

  if (!response.success || response.data == null) {
    throw Exception(response.message);
  }

  return response.data!;
});

// final chatMutationProvider =
//     AsyncNotifierProvider<ChatMutationNotifier, Mutation?>(
//       ChatMutationNotifier.new,
//     );

// final chatSocketProvider = Provider<ChatSocketNotifier>((ref) {
//   final socket = ref.watch(appSocketProvider);
//   return ChatSocketNotifier(ref, socket);
// });
