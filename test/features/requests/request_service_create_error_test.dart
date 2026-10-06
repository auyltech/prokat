import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/user_safety/user_safety_error_message.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

void main() {
  test('a rejected create keeps the stable backend code', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException.badResponse(
              statusCode: 400,
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 400,
                data: {
                  'success': false,
                  'error': contentNotAllowedErrorCode,
                  'message': 'The text contains content that is not allowed',
                },
              ),
            ),
          );
        },
      ),
    );

    final result = await RequestService(_TestApiClient(dio)).createRequest(
      categoryId: 'category-1',
      locationId: 'location-1',
      requiredOn: DateTime.utc(2026, 10, 7),
      requiredAt: DateTime.utc(2026, 10, 7, 9),
      comment: 'prohibited text',
    );

    expect(result.success, isFalse);
    expect(result.statusCode, 400);
    expect(result.errorCode, contentNotAllowedErrorCode);
  });
}
