import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_page.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';

Map<String, dynamic> proposal(
  String id,
  String status, {
  String booking = 'b1',
}) => {
  'id': id,
  'bookingId': booking,
  'createdById': 'client',
  'status': status,
  'price': 17000,
  'priceRate': 'PER_HOUR',
  'updatedAt': '2026-10-28T08:00:00Z',
};

void main() {
  test('legacy arrays are scoped, filtered and paginated locally', () {
    final rows = [
      proposal('a', 'CREATED'),
      proposal('x', 'CREATED', booking: 'other'),
      proposal('b', 'ACCEPTED'),
      proposal('c', 'CREATED'),
    ];
    const query = PriceNegotiationQuery(
      bookingId: 'b1',
      filter: PriceNegotiationListFilter.active,
      itemsPerPage: 1,
    );
    final first = parsePriceNegotiationPage(rows, query: query, page: 1);
    final second = parsePriceNegotiationPage(rows, query: query, page: 2);
    expect(first.items.single.id, 'a');
    expect(second.items.single.id, 'c');
    expect(first.count, 2);
    expect(
      parsePriceNegotiationPage(
        rows,
        query: query.withFilter(PriceNegotiationListFilter.history),
        page: 1,
      ).items.single.id,
      'b',
    );
  });

  test('new paginated envelope retains server count and subject guard', () {
    final result = parsePriceNegotiationPage(
      {
        'data': {
          'items': [proposal('a', 'CREATED')],
          'count': 25,
          'page': 2,
          'itemsPerPage': 20,
        },
      },
      query: const PriceNegotiationQuery(bookingId: 'b1'),
      page: 2,
    );
    expect(result.items.single.id, 'a');
    expect(result.count, 25);
    expect(result.page, 2);
  });

  test('canonical terminal status prevents an old event regaining actions', () {
    final event = proposal('a', 'CREATED');
    final terminal = PriceNegotiation.fromJson({
      ...event,
      'status': 'ACCEPTED',
      'updatedAt': '2026-10-28T08:01:00Z',
    });
    expect(
      resolveMessageNegotiation(event, [terminal]).status,
      PriceNegotiationStatus.accepted,
    );
    expect(resolveMessageNegotiation(event, []).isPending, isFalse);
    expect(
      resolveMessageNegotiation({...event, 'status': 'REJECTED'}, []).status,
      PriceNegotiationStatus.rejected,
    );
  });

  test('newer terminal event wins over stale canonical cache', () {
    final event = {
      ...proposal('a', 'ACCEPTED'),
      'updatedAt': '2026-10-28T08:02:00Z',
    };
    final stale = PriceNegotiation.fromJson(proposal('a', 'CREATED'));
    expect(
      resolveMessageNegotiation(event, [stale]).status,
      PriceNegotiationStatus.accepted,
    );
  });

  test(
    'unknown or incomplete terms are never acknowledged as just a price',
    () {
      for (final raw in [
        null,
        {'version': 2},
        {'version': 1},
      ]) {
        final parsed = PriceNegotiation.fromJson({
          ...proposal('a', 'CREATED'),
          'requiresTermsAcknowledgement': true,
          'proposedTerms': raw,
        });
        expect(parsed.requiresTermsAcknowledgement, isTrue);
        expect(parsed.canAcknowledgeTerms, isFalse);
      }
      expect(
        PriceNegotiation.fromJson(proposal('old', 'CREATED'))
            .canAcknowledgeTerms,
        isTrue,
      );
    },
  );
}
