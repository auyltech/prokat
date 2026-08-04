enum PriceNegotiationListFilter {
  active('ACTIVE'),
  history('HISTORY');

  const PriceNegotiationListFilter(this.apiValue);
  final String apiValue;
}

class PriceNegotiationQuery {
  const PriceNegotiationQuery({
    this.bookingId,
    this.offerId,
    this.filter,
    this.itemsPerPage = 20,
  }) : assert(
         (bookingId != null && offerId == null) ||
             (bookingId == null && offerId != null),
         'Provide exactly one bookingId or offerId',
       );

  final String? bookingId;
  final String? offerId;
  final PriceNegotiationListFilter? filter;
  final int itemsPerPage;

  PriceNegotiationQuery withFilter(PriceNegotiationListFilter value) {
    return PriceNegotiationQuery(
      bookingId: bookingId,
      offerId: offerId,
      filter: value,
      itemsPerPage: itemsPerPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PriceNegotiationQuery &&
      other.bookingId == bookingId &&
      other.offerId == offerId &&
      other.filter == filter &&
      other.itemsPerPage == itemsPerPage;

  @override
  int get hashCode => Object.hash(bookingId, offerId, filter, itemsPerPage);
}

PriceNegotiationQuery? priceNegotiationQueryFor({
  String? bookingId,
  String? offerId,
  PriceNegotiationListFilter filter = PriceNegotiationListFilter.active,
}) {
  final booking = (bookingId ?? '').trim();
  final offer = (offerId ?? '').trim();
  if (booking.isNotEmpty) {
    return PriceNegotiationQuery(bookingId: booking, filter: filter);
  }
  if (offer.isNotEmpty) {
    return PriceNegotiationQuery(offerId: offer, filter: filter);
  }
  return null;
}
