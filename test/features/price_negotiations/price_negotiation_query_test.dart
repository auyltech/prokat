import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';

void main() {
  test('query requires one subject and is value-equal', () {
    const booking = PriceNegotiationQuery(
      bookingId: 'booking-1',
      filter: PriceNegotiationListFilter.active,
    );
    const sameBooking = PriceNegotiationQuery(
      bookingId: 'booking-1',
      filter: PriceNegotiationListFilter.active,
    );

    expect(booking, sameBooking);
    expect(booking, isNot(const PriceNegotiationQuery(offerId: 'offer-1')));
    expect(
      () => PriceNegotiationQuery(bookingId: 'booking-1', offerId: 'offer-1'),
      throwsAssertionError,
    );
    expect(() => PriceNegotiationQuery(), throwsAssertionError);
  });
}
