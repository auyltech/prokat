import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_helper.dart';
import '../errors/api_exception.dart';
import 'api_response.dart';

abstract class BaseRepository {
  Future<ApiResponse<T>> handleRequest<T>(
    Future<Response> Function() request,
    T Function(dynamic data) parser, {
    String fallbackMessage = "Request failed",
  }) async {
    try {
      final response = await request();

      final statusCode = response.statusCode ?? 0;
      final responseData = response.data;

      final isSuccess = statusCode >= 200 && statusCode < 300;

      if (!isSuccess) {
        return ApiResponse.failure(
          message: extractBackendMessage(responseData),
          error: responseData,
          statusCode: statusCode,
        );
      }

      try {
        final rawData = responseData is Map<String, dynamic>
            ? responseData["data"]
            : responseData;

        final parsedData = parser(rawData);

        return ApiResponse.success(
          parsedData,
          message: extractBackendMessage(responseData),
          statusCode: statusCode,
        );
      } catch (e) {
        return ApiResponse.failure(
          message: "Failed to read server response",
          error: e,
          statusCode: statusCode,
        );
      }
    } on DioException catch (e) {
      final message = extractDioExceptionMessage(e);

      return ApiResponse.failure(
        message: message,
        error: e.response?.data ?? e,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(message: "Unexpected error", error: e);
    }
  }

  Future<T> execute<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } catch (e) {
      throw ApiException(message: "Unexpected error", data: e);
    }
  }
}
