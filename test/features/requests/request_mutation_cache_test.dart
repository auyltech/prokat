import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

void main() {
  test('cancellation does not instantiate request history', () async {
    final requests = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {'message': 'ok'},
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        requestServiceProvider.overrideWithValue(
          RequestService(_TestApiClient(dio)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(requestMutationProvider.notifier)
        .cancelRequest('request-1');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(result.success, isTrue);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'PATCH');
    expect(requests.single.path, '/requests/request-1/cancel');
  });
}
