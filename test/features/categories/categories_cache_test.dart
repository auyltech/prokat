import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/state/category_service.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

void main() {
  test(
    'catalogue stays fresh for 24 hours and hard refresh still fetches',
    () async {
      var calls = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            calls++;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {'id': 'category-1', 'name': 'Excavators', 'sortIndex': 1},
                  ],
                },
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          categoryServiceProvider.overrideWithValue(
            CategoryService(_TestApiClient(dio)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(categoriesProvider.future);
      expect(calls, 1);

      await container.read(categoriesProvider.notifier).refreshIfStale();
      expect(calls, 1);

      await container.read(categoriesProvider.notifier).refresh();
      expect(calls, 2);
    },
  );
}
