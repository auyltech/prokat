class QueryState<T> {
  final List<T> items;

  final int page;
  final int itemsPerPage;
  final int count;

  final DateTime? lastFetchedAt;
  final bool isRefreshing;
  final bool isLoadingMore;

  const QueryState({
    this.items = const [],

    this.page = 1,
    required this.itemsPerPage,
    required this.count,

    this.lastFetchedAt,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  bool get isStale {
    if (lastFetchedAt == null) return true;

    return DateTime.now().difference(lastFetchedAt!) >
        const Duration(seconds: 30);
  }

  int get totalPages => (count / itemsPerPage).ceil();
  bool get hasMore => page < totalPages;
  bool get isLastPage => !hasMore;

  QueryState<T> copyWith({
    List<T>? items,
    int? page,
    int? itemsPerPage,
    int? count,
    DateTime? lastFetchedAt,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return QueryState(
      items: items ?? this.items,
      page: page ?? this.page,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      count: count ?? this.count,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
