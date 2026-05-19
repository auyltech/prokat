import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/api_provider.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';
import 'package:prokat/features/notifications/services/notification_api_service.dart';

enum NotificationSource { fcm, socket, local }

class NotificationState {
  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  final Map<String, DateTime> recentIds;

  const NotificationState({
    this.items = const <AppNotification>[],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.recentIds = const {},
  });

  NotificationState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    Map<String, DateTime>? recentIds,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      recentIds: recentIds ?? this.recentIds,
    );
  }
}

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationApiService(dio);
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final api = ref.watch(notificationApiServiceProvider);
  return NotificationNotifier(api);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  static const int _defaultLimit = 20;
  static const Duration _dedupeTtl = Duration(minutes: 10);

  final NotificationApiService api;

  NotificationNotifier(this.api) : super(const NotificationState());

  void clearOnLogout() {
    state = const NotificationState();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      page: 1,
      hasMore: true,
    );

    try {
      final items = await api.getNotifications(page: 1, limit: _defaultLimit);
      state = state.copyWith(
        isLoading: false,
        items: items,
        hasMore: items.length >= _defaultLimit,
        error: null,
      );

      await fetchUnreadCount();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final items = await api.getNotifications(page: 1, limit: _defaultLimit);
      state = state.copyWith(
        isRefreshing: false,
        items: items,
        page: 1,
        hasMore: items.length >= _defaultLimit,
        error: null,
      );

      await syncUnreadCountFromServer();
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final more = await api.getNotifications(
        page: nextPage,
        limit: _defaultLimit,
      );

      state = state.copyWith(
        isLoadingMore: false,
        page: nextPage,
        hasMore: more.length >= _defaultLimit,
        items: [...state.items, ...more],
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await api.getUnreadCount();
      // Treat server as source of truth when it is reachable.
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // Best-effort: keep local unreadCount.
    }
  }

  Future<void> syncUnreadCountFromServer() async {
    await fetchUnreadCount();
  }

  void handleIncomingNotification(
    AppNotification notification, {
    required NotificationSource source,
  }) {
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
    final nextItems = index == -1
        ? [notification, ...state.items]
        : [
            notification,
            ...state.items.where((n) => n.id != id),
          ];

    final shouldIncrementUnread = notification.isUnread;
    final nextUnread = shouldIncrementUnread ? state.unreadCount + 1 : state.unreadCount;

    state = state.copyWith(
      items: nextItems,
      unreadCount: nextUnread,
      recentIds: Map.unmodifiable(updatedRecentIds),
      error: null,
    );
  }

  Future<void> markAsRead(String id) async {
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
    state = state.copyWith(items: updatedItems, unreadCount: nextUnread, error: null);

    try {
      await api.markAsRead(trimmed);
      await syncUnreadCountFromServer();
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();

    final updatedItems = state.items
        .map((n) => n.isRead ? n : n.copyWith(readAt: now))
        .toList(growable: false);

    state = state.copyWith(items: updatedItems, unreadCount: 0, error: null);

    try {
      await api.markAllAsRead();
      await syncUnreadCountFromServer();
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;

    final index = state.items.indexWhere((n) => n.id == trimmed);
    if (index == -1) return;

    final removed = state.items[index];
    final nextItems = [...state.items]..removeAt(index);

    final nextUnread =
        removed.isUnread && state.unreadCount > 0 ? state.unreadCount - 1 : state.unreadCount;

    state = state.copyWith(items: nextItems, unreadCount: nextUnread, error: null);

    try {
      await api.deleteNotification(trimmed);
      await syncUnreadCountFromServer();
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Map<String, DateTime> _pruneRecentIds(Map<String, DateTime> existing, DateTime now) {
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
