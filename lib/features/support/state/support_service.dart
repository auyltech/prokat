import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';

class SupportService {
  final ApiClient apiClient;

  SupportService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<void>> submitInquiry({
    required String fullName,
    required String? email,
    required String? phoneNumber,
    required String topic,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        '/contact',
        data: {
          "fullName": fullName,
          "email": email,
          "phoneNumber": phoneNumber,
          "topic": topic,
          "message": message,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Inquiry submitted",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }
}
