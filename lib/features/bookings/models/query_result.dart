class QueryResult<T> {
  final List<T> items;
  final int page;
  final int itemsPerPage;
  final int count;

  const QueryResult({
    required this.items,
    required this.page,
    required this.itemsPerPage,
    required this.count,
  });
}
