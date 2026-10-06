import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';
import 'package:prokat/features/notifications/services/notification_state.dart';

class NotificationNotifier extends StateNotifier<NotificationState> {
  static const int _defaultLimit = 20;
  static const Duration _dedupeTtl = Duration(minutes: 10);

  final NotificationApiService api;

  NotificationNotifier(this.api) : super(const NotificationState());

  int _scopeEpoch = 0;
  void changeScope() {
    _scopeEpoch++;
    state = const NotificationState();
    unawaited(loadInitial());
  }

  void clearOnLogout() {
    _scopeEpoch++;
    state = const NotificationState();
  }

  Future<void> loadInitial() async {
    final epoch = _scopeEpoch;
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      page: 1,
      hasMore: true,
    );

    try {
      final items = await api.getNotifications(page: 1, limit: _defaultLimit);
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: items.length >= _defaultLimit,
        error: null,
      );

      await fetchUnreadCount();
      if (!mounted || epoch != _scopeEpoch) return;
    } catch (error) {
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    final epoch = _scopeEpoch;
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final items = await api.getNotifications(page: 1, limit: _defaultLimit);
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        isRefreshing: false,
        items: items,
        page: 1,
        hasMore: items.length >= _defaultLimit,
        error: null,
      );

      await syncUnreadCountFromServer();
      if (!mounted || epoch != _scopeEpoch) return;
    } catch (error) {
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        isRefreshing: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    final epoch = _scopeEpoch;
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final more = await api.getNotifications(
        page: nextPage,
        limit: _defaultLimit,
      );
      if (!mounted || epoch != _scopeEpoch) return;

      state = state.copyWith(
        isLoadingMore: false,
        page: nextPage,
        hasMore: more.length >= _defaultLimit,
        items: [...state.items, ...more],
      );
    } catch (error) {
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> fetchUnreadCount() async {
    final epoch = _scopeEpoch;
    try {
      final count = await api.getUnreadCount();
      if (!mounted || epoch != _scopeEpoch) return;
      // Treat server as source of truth when it is reachable.
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // Best-effort: keep local unreadCount.
    }
  }

  Future<void> syncUnreadCountFromServer() async {
    final epoch = _scopeEpoch;
    await fetchUnreadCount();
    if (!mounted || epoch != _scopeEpoch) return;
  }

  void handleIncomingNotification(
    AppNotification notification, {
    required NotificationSource source,
  }) {
    if (!api.accepts(notification)) return;
    final id = notification.id.trim();

    if (id.isEmpty) return;

    final now = DateTime.now();
    final pruned = _pruneRecentIds(state.recentIds, now);

    if (pruned.containsKey(id)) {
      state = state.copyWith(recentIds: pruned);
      return;
    }

    final updatedRecentIds = Map<String, DateTime>.from(pruned)..[id] = now;

    final index = state.items.indexWhere((n) => n.id == id);
    if (index != -1) {
      state = state.copyWith(recentIds: Map.unmodifiable(updatedRecentIds));
      return;
    }
    final nextItems = index == -1
        ? [notification, ...state.items]
        : [notification, ...state.items.where((n) => n.id != id)];

    final shouldIncrementUnread = notification.isUnread;
    final nextUnread = shouldIncrementUnread
        ? state.unreadCount + 1
        : state.unreadCount;

    state = state.copyWith(
      items: nextItems,
      unreadCount: nextUnread,
      recentIds: Map.unmodifiable(updatedRecentIds),
      error: null,
    );
  }

  Future<void> markAsRead(String id) async {
    final epoch = _scopeEpoch;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;

    final index = state.items.indexWhere((n) => n.id == trimmed);
    if (index == -1) {
      return;
    }

    final existing = state.items[index];
    if (existing.isRead) return;

    final updatedItems = List<AppNotification>.from(state.items);
    updatedItems[index] = existing.copyWith(readAt: DateTime.now());

    final nextUnread = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
    state = state.copyWith(
      items: updatedItems,
      unreadCount: nextUnread,
      error: null,
    );

    try {
      await api.markAsRead(trimmed);
      if (!mounted || epoch != _scopeEpoch) return;
      await syncUnreadCountFromServer();
      if (!mounted || epoch != _scopeEpoch) return;
    } catch (error) {
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final epoch = _scopeEpoch;
    final now = DateTime.now();

    final updatedItems = state.items
        .map((n) => n.isRead ? n : n.copyWith(readAt: now))
        .toList(growable: false);

    state = state.copyWith(items: updatedItems, unreadCount: 0, error: null);

    try {
      await api.markAllAsRead();
      if (!mounted || epoch != _scopeEpoch) return;
      await syncUnreadCountFromServer();
      if (!mounted || epoch != _scopeEpoch) return;
    } catch (error) {
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    await deleteNotifications([id]);
  }

  /// Removes every loaded row in a grouped chat notification.
  Future<void> deleteNotifications(List<String> ids) async {
    final epoch = _scopeEpoch;
    final idSet = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (idSet.isEmpty) return;

    final removedUnread = state.items
        .where((item) => idSet.contains(item.id) && item.isUnread)
        .length;
    final nextItems = state.items
        .where((item) => !idSet.contains(item.id))
        .toList(growable: false);
    if (nextItems.length == state.items.length) return;

    final nextUnread = state.unreadCount - removedUnread;

    state = state.copyWith(
      items: nextItems,
      unreadCount: nextUnread < 0 ? 0 : nextUnread,
      error: null,
    );

    try {
      for (final id in idSet) {
        await api.deleteNotification(id);
        if (!mounted || epoch != _scopeEpoch) return;
      }
      await syncUnreadCountFromServer();
      if (!mounted || epoch != _scopeEpoch) return;
    } catch (error) {
      if (!mounted || epoch != _scopeEpoch) return;
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Map<String, DateTime> _pruneRecentIds(
    Map<String, DateTime> existing,
    DateTime now,
  ) {
    if (existing.isEmpty) return const {};

    final cutoff = now.subtract(_dedupeTtl);
    final next = <String, DateTime>{};
    for (final entry in existing.entries) {
      if (entry.value.isAfter(cutoff)) {
        next[entry.key] = entry.value;
      }
    }
    return UnmodifiableMapView(next);
  }
}
