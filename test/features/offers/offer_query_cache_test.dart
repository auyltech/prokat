import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

Map<String, dynamic> _offer(String id, String createdAt) => {
  'id': id,
  'status': 'CREATED',
  'requestId': 'request-1',
  'chatId': 'chat-1',
  'equipmentId': 'equipment-1',
  'price': 100,
  'createdAt': createdAt,
};

void main() {
  test(
    'family keys are value-equal and pagination deduplicates by id',
    () async {
      final requestedPaths = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            final page = options.queryParameters['page'] as int;
            final items = page == 1
                ? [
                    _offer('offer-2', '2026-01-02T00:00:00.000Z'),
                    _offer('offer-1', '2026-01-01T00:00:00.000Z'),
                  ]
                : [
                    _offer('offer-2', '2026-01-02T00:00:00.000Z'),
                    _offer('offer-3', '2025-12-31T00:00:00.000Z'),
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
          offersServiceProvider.overrideWithValue(
            OffersService(_TestApiClient(dio)),
          ),
        ],
      );
      addTearDown(container.dispose);

      const firstKey = OfferQuery(
        filter: OfferListFilter.active,
        requestId: 'request-1',
        itemsPerPage: 2,
      );
      const equalKey = OfferQuery(
        filter: OfferListFilter.active,
        requestId: 'request-1',
        itemsPerPage: 2,
      );
      expect(firstKey, equalKey);

      await container.read(clientOffersProvider(firstKey).future);
      await container.read(clientOffersProvider(equalKey).notifier).loadMore();
      final result = container
          .read(clientOffersProvider(firstKey))
          .requireValue;
      expect(result.items.map((item) => item.id), [
        'offer-2',
        'offer-1',
        'offer-3',
      ]);
      expect(result.hasMore, isFalse);

      await container.read(ownerOffersProvider(firstKey).future);
      expect(requestedPaths, containsAll(['/offers', '/offers/owner']));
    },
  );
}
