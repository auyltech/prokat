enum OfferListFilter {
  active('ACTIVE'),
  history('HISTORY');

  const OfferListFilter(this.apiValue);
  final String apiValue;
}

class OfferQuery {
  const OfferQuery({this.filter, this.requestId, this.itemsPerPage = 20});

  const OfferQuery.active()
    : filter = OfferListFilter.active,
      requestId = null,
      itemsPerPage = 20;

  const OfferQuery.history()
    : filter = OfferListFilter.history,
      requestId = null,
      itemsPerPage = 20;

  final OfferListFilter? filter;
  final String? requestId;
  final int itemsPerPage;

  @override
  bool operator ==(Object other) =>
      other is OfferQuery &&
      other.filter == filter &&
      other.requestId == requestId &&
      other.itemsPerPage == itemsPerPage;

  @override
  int get hashCode => Object.hash(filter, requestId, itemsPerPage);
}
