enum FetchStatus { initial, loading, success, empty, stale, refreshing, error }

enum PaginationStatus { idle, loadingMore, error }

FetchStatus resolveFetchStatus<T>(List<T> data) {
  return data.isEmpty ? FetchStatus.empty : FetchStatus.success;
}
