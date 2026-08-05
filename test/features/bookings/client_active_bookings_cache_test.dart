import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

void main() {
  test(
    'entry refresh, hard refresh, coalescing, and stale invalidation',
    () async {
      var calls = 0;
      var fail = false;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            calls++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: fail ? 500 : 200,
                data: fail
                    ? {'message': 'offline'}
                    : {
                        'data': <dynamic>[],
                        'page': 1,
                        'itemsPerPage': 10,
                        'count': 0,
                      },
              ),
            );
          },
        ),
      );

      final container = ProviderContainer(
        overrides: [
          bookingServiceProvider.overrideWithValue(
            BookingService(_TestApiClient(dio)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(clientActiveBookingsProvider.future);
      expect(calls, 1);

      final notifier = container.read(clientActiveBookingsProvider.notifier);
      await notifier.refreshIfStale();
      expect(calls, 1);

      await Future.wait([notifier.refresh(), notifier.refresh()]);
      expect(calls, 2);

      final lastSuccess = container
          .read(clientActiveBookingsProvider)
          .requireValue
          .lastFetchedAt;
      fail = true;
      await notifier.refresh();
      final afterFailure = container
          .read(clientActiveBookingsProvider)
          .requireValue;
      expect(afterFailure.items, initial.items);
      expect(afterFailure.lastFetchedAt, lastSuccess);
      expect(afterFailure.refreshError, isNotNull);

      fail = false;
      await notifier.invalidate();
      expect(
        container.read(clientActiveBookingsProvider).requireValue.lastFetchedAt,
        isNull,
      );
      await Future.wait([notifier.refreshIfStale(), notifier.refreshIfStale()]);
      expect(calls, 4);
    },
  );

  test('an initial failure remains AsyncError', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 500,
            data: {'message': 'offline'},
          ),
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        bookingServiceProvider.overrideWithValue(
          BookingService(_TestApiClient(dio)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(clientActiveBookingsProvider.future),
      throwsA(isA<Exception>()),
    );
    expect(container.read(clientActiveBookingsProvider), isA<AsyncError>());
  });
}
