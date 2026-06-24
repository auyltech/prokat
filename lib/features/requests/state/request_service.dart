import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:dio/dio.dart';

class RequestService {
  final ApiClient apiClient;

  RequestService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<RequestModel>>> getClientRequests() async {
    try {
      final response = await _dio.get('/requests');

      return handleApiResponse<List<RequestModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected requests list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid request item");
            }

            return RequestModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load requests",
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

  Future<ApiResponse<void>> createRequest({
    required String categoryId,
    required String locationId,
    required String capacity,
    required DateTime requiredOn,
    DateTime? requiredAt,
    String? comment,
    required int offeredRate,
  }) async {
    try {
      final response = await _dio.post(
        '/requests',
        data: {
          "categoryId": categoryId,
          "locationId": locationId,
          "capacity": capacity,
          // 1. Force UTC transformation before stringifying
          "requiredOn": requiredOn.toUtc().toIso8601String(),
          "requiredAt": requiredAt?.toUtc().toIso8601String(),
          "comment": comment,
          "offeredRate": offeredRate,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Request created",
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

  Future<ApiResponse<void>> updateRequest({
    required String id,
    String? locationId,
    DateTime? requiredOn,
    DateTime? requiredAt,
    int? offeredRate,
  }) async {
    try {
      final response = await _dio.patch(
        '/requests/$id',
        data: {
          "locationId": ?locationId,
          if (requiredOn != null) "requiredOn": requiredOn.toIso8601String(),
          if (requiredAt != null) "requiredAt": requiredAt.toIso8601String(),
          "offeredRate": ?offeredRate,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Request saved",
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

  Future<ApiResponse<void>> cancelRequest(String id) async {
    try {
      final response = await _dio.patch(
        '/requests/$id/cancel',
        data: {"id": id, "status": "CANCELLED"},
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Request cancelled",
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

  Future<ApiResponse<void>> viewRequest(String id) async {
    try {
      final response = await _dio.patch(
        '/requests/$id/view',
        data: {"id": id, "status": "hidden"},
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Request hidden",
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

  Future<ApiResponse<List<RequestModel>>> getOwnerRequests() async {
    try {
      final response = await _dio.get('/requests/owner');

      return handleApiResponse<List<RequestModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected requests list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid request item");
            }

            return RequestModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load requests",
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
