import 'package:flutter/material.dart';
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
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadInitial();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(notificationProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return ListView(
                  padding: EdgeInsets.all(12),
                  children: [EmptyStateTile(title: l10n.loading)],
                );
              }

              if ((state.error ?? '').isNotEmpty) {
                return ListView(
                  padding: EdgeInsets.all(12),
                  children: [EmptyStateTile(title: state.error ?? l10n.error)],
                );
              }

              if (state.items.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(12),
                  children: [
                    EmptyStateTile(
                      icon: Icons.notifications_none,
                      imageName: "empty_notifications.png",
                      title: l10n.noNotificationsYet,
                      subtitle: "You don't have any notifications",
                    ),
                  ],
                );
              }

              return ListView.separated(
                itemCount: state.items.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    if (!state.isLoadingMore) {
                      Future.microtask(
                        () =>
                            ref.read(notificationProvider.notifier).loadMore(),
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

                  final item = state.items[index];

                  return NotificationTile(
                    notification: item,
                    onTap: () async {
                      // don't await read
                      ref
                          .read(notificationProvider.notifier)
                          .markAsRead(item.id);

                      await ref
                          .read(notificationNavigationServiceProvider)
                          .navigate(item);
                    },
                    onDelete: () => ref
                        .read(notificationProvider.notifier)
                        .deleteNotification(item.id),
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
