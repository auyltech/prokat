import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/models/chat_lookup.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/models/notification_group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/widgets/notification_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() {
        unawaited(ref.read(notificationProvider.notifier).loadInitial());
      }),
    );
  }

  Future<void> _onRefresh() async {
    await ref.read(notificationProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationProvider);
    final groups = groupNotifications(state.items);
    final currentUserId = ref.watch(authProvider).currentUserId ?? '';
    final clientChats =
        ref.watch(clientChatsProvider).valueOrNull?.items ??
        const <ChatModel>[];
    final ownerChats =
        ref.watch(ownerChatsProvider).valueOrNull?.items ?? const <ChatModel>[];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [EmptyStateTile(title: l10n.loading)],
                );
              }

              if ((state.error ?? '').isNotEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [EmptyStateTile(title: state.error ?? l10n.error)],
                );
              }

              if (state.items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    EmptyStateTile(
                      icon: Icons.notifications_none,
                      imageName: "empty_notifications.png",
                      title: l10n.noNotificationsYet,
                      subtitle: l10n.youHaveNoNotifications,
                    ),
                  ],
                );
              }

              return ListView.separated(
                itemCount: groups.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  if (index >= groups.length) {
                    if (!state.isLoadingMore) {
                      unawaited(
                        Future.microtask(
                          () => ref
                              .read(notificationProvider.notifier)
                              .loadMore(),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: state.isLoadingMore
                            ? const CircularProgressIndicator()
                            : const SizedBox.shrink(),
                      ),
                    );
                  }

                  final group = groups[index];
                  final item = group.latest;
                  final ids = group.items
                      .map((notification) => notification.id)
                      .toList(growable: false);

                  Future<void> open() async {
                    for (final notification in group.items.where(
                      (item) => item.isUnread,
                    )) {
                      unawaited(
                        ref
                            .read(notificationProvider.notifier)
                            .markAsRead(notification.id),
                      );
                    }

                    await ref
                        .read(notificationNavigationServiceProvider)
                        .navigate(item);
                  }

                  void remove() {
                    unawaited(
                      ref
                          .read(notificationProvider.notifier)
                          .deleteNotifications(ids),
                    );
                  }

                  if (group.isChat) {
                    return _ChatGroupTile(
                      notification: item,
                      fallbackUnread: group.unreadCount,
                      currentUserId: currentUserId,
                      clientChats: clientChats,
                      ownerChats: ownerChats,
                      onTap: () {
                        unawaited(open());
                      },
                      onDelete: remove,
                    );
                  }

                  return NotificationTile(
                    notification: item,
                    onTap: () {
                      unawaited(open());
                    },
                    onDelete: remove,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatGroupTile extends ConsumerWidget {
  final AppNotification notification;
  final int fallbackUnread;
  final String currentUserId;
  final List<ChatModel> clientChats;
  final List<ChatModel> ownerChats;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatGroupTile({
    required this.notification,
    required this.fallbackUnread,
    required this.currentUserId,
    required this.clientChats,
    required this.ownerChats,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listed = _listedChat(
      chatId: notification.chatId,
      clientChats: clientChats,
      ownerChats: ownerChats,
    );
    final resolved = ref
        .watch(chatResolverProvider(ChatLookup.byId(notification.chatId)))
        .valueOrNull;
    final chat = listed ?? resolved;
    final senderName = chat?.displayTitle(
      currentUserId,
      ownerFallback: l10n.nameNotSpecified,
      clientFallback: l10n.nameNotSpecified,
    );

    return NotificationTile(
      notification: notification,
      chatStyle: true,
      senderName: senderName,
      senderImageUrl: chat?.displayImageUrl(currentUserId: currentUserId),
      unreadCount:
          listed?.newMessagesCount ??
          resolved?.newMessagesCount ??
          fallbackUnread,
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}

ChatModel? _listedChat({
  required String? chatId,
  required List<ChatModel> clientChats,
  required List<ChatModel> ownerChats,
}) {
  final id = chatId?.trim() ?? '';
  if (id.isEmpty) return null;
  for (final chat in clientChats) {
    if (chat.id == id) return chat;
  }
  for (final chat in ownerChats) {
    if (chat.id == id) return chat;
  }
  return null;
}
