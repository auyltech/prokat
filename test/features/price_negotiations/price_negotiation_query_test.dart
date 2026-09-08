import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

Map<String, dynamic> _negotiation(String id, String createdAt) => {
  'id': id,
  'offerId': 'offer-1',
  'price': 100,
  'status': 'CREATED',
  'createdAt': createdAt,
};

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

  test('offer subject pagination deduplicates and stops at count', () async {
    final requestedPaths = <String>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestedPaths.add(options.path);
          final page = options.queryParameters['page'] as int;
          final items = page == 1
              ? [
                  _negotiation('negotiation-2', '2026-01-02T00:00:00.000Z'),
                  _negotiation('negotiation-1', '2026-01-01T00:00:00.000Z'),
                ]
              : [
                  _negotiation('negotiation-2', '2026-01-02T00:00:00.000Z'),
                  _negotiation('negotiation-3', '2025-12-31T00:00:00.000Z'),
                ];
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {
                  'items': items,
                  'page': page,
                  'itemsPerPage': 2,
                  'count': 3,
                },
              },
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        authenticatedSessionScopeKeyProvider.overrideWithValue(
          const AuthenticatedSessionScopeKey.forUser('test-user'),
        ),
        priceNegotiationServiceProvider.overrideWithValue(
          PriceNegotiationService(_TestApiClient(dio)),
        ),
      ],
    );
    addTearDown(container.dispose);

    const query = PriceNegotiationQuery(
      offerId: 'offer-1',
      filter: PriceNegotiationListFilter.active,
      itemsPerPage: 2,
    );
    await container.read(priceNegotiationsProvider(query).future);
    await container.read(priceNegotiationsProvider(query).notifier).loadMore();

    final result = container
        .read(priceNegotiationsProvider(query))
        .requireValue;
    expect(result.items.map((item) => item.id), [
      'negotiation-2',
      'negotiation-1',
      'negotiation-3',
    ]);
    expect(result.hasMore, isFalse);
    expect(requestedPaths, everyElement('/price-negotiations/offer/offer-1'));
  });
}
