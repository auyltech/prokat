import 'package:prokat/features/notifications/models/app_notification.dart';

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
