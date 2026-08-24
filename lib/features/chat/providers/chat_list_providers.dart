import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/notifiers/client_chats_notifier.dart';
import 'package:prokat/features/chat/notifiers/owner_chats_notifier.dart';

final clientChatsProvider =
    AsyncNotifierProvider<ClientChatsNotifier, QueryState<ChatModel>>(
      ClientChatsNotifier.new,
    );

final ownerChatsProvider =
    AsyncNotifierProvider<OwnerChatsNotifier, QueryState<ChatModel>>(
      OwnerChatsNotifier.new,
    );
