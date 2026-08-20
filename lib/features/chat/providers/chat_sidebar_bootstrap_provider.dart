import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/models/chat_sidebar_update.dart';
import 'package:prokat/features/chat/providers/chat_dependencies.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/utils/chat_resume_sync_observer.dart';
import 'package:prokat/features/chat/utils/chat_sidebar_update_utils.dart';

final chatSidebarBootstrapProvider = Provider<void>((ref) {
  final socketService = ref.watch(chatSocketServiceProvider);
  void Function()? removeListener;
  var started = false;

  void detach() {
    removeListener?.call();
    removeListener = null;
    started = false;
  }

  void applyUpdate(ChatSidebarUpdate update) {
    final currentUserId = ref.read(authProvider).currentUserId;
    final isThreadOpen = socketService.activeChatId == update.chatId;

    var refreshClient = false;
    var refreshOwner = false;

    for (final filter in ChatListFilter.values) {
      final client = clientChatsByFilterProvider(filter);
      if (ref.exists(client)) {
        final status = ref
            .read(client.notifier)
            .applySidebarUpdate(
              update: update,
              currentUserId: currentUserId,
              isThreadOpen: isThreadOpen,
            );
        if (status == ChatSidebarApplyStatus.notFound) {
          refreshClient = true;
        }
      }

      final owner = ownerChatsByFilterProvider(filter);
      if (ref.exists(owner)) {
        final status = ref
            .read(owner.notifier)
            .applySidebarUpdate(
              update: update,
              currentUserId: currentUserId,
              isThreadOpen: isThreadOpen,
            );
        if (status == ChatSidebarApplyStatus.notFound) {
          refreshOwner = true;
        }
      }
    }

    final lastMessage = update.lastMessage;
    if (lastMessage != null && ref.exists(currentChatProvider(update.chatId))) {
      ref
          .read(currentChatProvider(update.chatId).notifier)
          .setLastMessage(lastMessage);
    }

    if (refreshClient) {
      unawaited(ref.read(clientChatsProvider.notifier).refresh());
    }
    if (refreshOwner) {
      unawaited(ref.read(ownerChatsProvider.notifier).refresh());
    }
  }

  Future<void> startIfReady() async {
    final session = ref.read(authProvider).session;
    if (session == null) {
      detach();
      return;
    }

    if (started) return;

    started = true;
    removeListener = socketService.onSidebarUpdate(applyUpdate);

    try {
      await socketService.connect();
    } catch (_) {}
  }

  void refreshListsAfterBackground() {
    if (ref.read(authProvider).session == null) return;

    for (final filter in ChatListFilter.values) {
      final client = clientChatsByFilterProvider(filter);
      if (ref.exists(client)) {
        unawaited(ref.read(client.notifier).refresh());
      }
      final owner = ownerChatsByFilterProvider(filter);
      if (ref.exists(owner)) {
        unawaited(ref.read(owner.notifier).refresh());
      }
    }
  }

  final lifecycleObserver = ChatResumeSyncObserver(
    onResumeFromBackground: () {
      unawaited(startIfReady());
      refreshListsAfterBackground();
    },
  );

  try {
    WidgetsBinding.instance.addObserver(lifecycleObserver);
  } catch (_) {}

  ref.listen(authProvider, (previous, next) {
    if (previous?.session != null && next.session == null) {
      detach();
      return;
    }

    if (next.session != null) {
      unawaited(startIfReady());
    }
  });

  ref.onDispose(() {
    try {
      WidgetsBinding.instance.removeObserver(lifecycleObserver);
    } catch (_) {}
    detach();
  });

  unawaited(startIfReady());
});
