import 'package:prokat/core/errors/app_error.dart';

class QueryState<T> {
  final List<T> items;

  final int page;
  final int itemsPerPage;
  final int count;

  final DateTime? lastFetchedAt;
  final AppError? refreshError;
  final bool isRefreshing;
  final bool isLoadingMore;

  const QueryState({
    this.items = const [],

    this.page = 1,
    required this.itemsPerPage,
    required this.count,

    this.lastFetchedAt,
    this.refreshError,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  bool get isStale => isStaleAfter(const Duration(seconds: 30));

  bool isStaleAfter(Duration ttl) {
    if (lastFetchedAt == null) return true;

    return DateTime.now().difference(lastFetchedAt!) > ttl;
  }

  int get totalPages => itemsPerPage <= 0 ? 0 : (count / itemsPerPage).ceil();
  bool get hasMore => page < totalPages;
  bool get isLastPage => !hasMore;

  QueryState<T> withRefreshError(Object error) {
    return copyWith(
      isRefreshing: false,
      refreshError: () => AppError(
        type: ErrorType.unknown,
        code: 'QUERY_REFRESH_FAILED',
        message: error.toString(),
      ),
    );
  }

  QueryState<T> copyWith({
    List<T>? items,
    int? page,
    int? itemsPerPage,
    int? count,
    DateTime? Function()? lastFetchedAt,
    AppError? Function()? refreshError,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return QueryState(
      items: items ?? this.items,
      page: page ?? this.page,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      count: count ?? this.count,
      lastFetchedAt: lastFetchedAt != null
          ? lastFetchedAt()
          : this.lastFetchedAt,
      refreshError: refreshError != null ? refreshError() : this.refreshError,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
