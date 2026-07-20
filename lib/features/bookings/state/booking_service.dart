import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:prokat/features/bookings/models/work_status.dart';

class BookingService {
  final ApiClient apiClient;

  BookingService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<QueryResult<BookingModel>>> getClientBookings({
    required int page,
    required int itemsPerPage,
    required String status,
  }) async {
    try {
      final response = await _dio.get(
        "/bookings",
        queryParameters: {
          "page": page,
          "itemsPerPage": itemsPerPage,
          "status": status,
        },
      );

      return handleApiResponse<QueryResult<BookingModel>>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic> && data.containsKey("data")) {
            throw const FormatException("Expected paginated booking response");
          }

          final itemsJson = data["data"];

          if (itemsJson is! List) {
            throw const FormatException("Expected booking list");
          }

          final items = itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid booking item");
            }

            return BookingModel.fromJson(item);
          }).toList();

          return QueryResult<BookingModel>(
            items: items,
            page: (data["page"] as num?)?.toInt() ?? page,
            itemsPerPage:
                (data["itemsPerPage"] as num?)?.toInt() ?? itemsPerPage,
            count: (data["count"] as num?)?.toInt() ?? items.length,
          );
        },
        fallbackMessage: "Failed to load bookings",
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
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }

  Future<ApiResponse<QueryResult<BookingModel>>> getOwnerBookings({
    required int page,
    required int itemsPerPage,
    required String status,
  }) async {
    try {
      final response = await _dio.get(
        "/bookings/owner",
        queryParameters: {
          "page": page,
          "itemsPerPage": itemsPerPage,
          "status": status,
        },
      );

      return handleApiResponse<QueryResult<BookingModel>>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic> && data.containsKey("data")) {
            throw const FormatException("Expected paginated booking response");
          }

          final itemsJson = data["data"];

          if (itemsJson is! List) {
            throw FormatException("Expected booking list");
          }

          final items = itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid booking item");
            }

            return BookingModel.fromJson(item);
          }).toList();

          return QueryResult<BookingModel>(
            items: items,
            page: (data["page"] as num?)?.toInt() ?? page,
            itemsPerPage:
                (data["itemsPerPage"] as num?)?.toInt() ?? itemsPerPage,
            count: (data["count"] as num?)?.toInt() ?? items.length,
          );
        },
        fallbackMessage: "Failed to load bookings",
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
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }

  Future<ApiResponse<void>> createBooking(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/bookings", data: data);

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Booking created",
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
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }

  Future<ApiResponse<void>> updateBookingStatus({
    required String id,
    BookingStatus? status,
    WorkStatus? workStatus,
    String? cancelReason,
  }) async {
    try {
      final response = await _dio.patch(
        "/bookings/$id/status",
        data: {
          "id": id,
          "status": status?.name,
          "workStatus": workStatus?.name,
          "cancelReason": cancelReason,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Booking created",
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

  Future<ApiResponse<void>> updateBookingWorkStatus({
    required String id,
    BookingStatus? status,
    WorkStatus? workStatus,
  }) async {
    try {
      final response = await _dio.patch(
        "/bookings/$id/workstatus",
        data: {
          "id": id,
          "status": status?.name,
          "workStatus": workStatus?.name,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Booking created",
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
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }
}
