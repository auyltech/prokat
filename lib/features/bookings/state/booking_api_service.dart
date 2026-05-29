import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';

class BookingApiService {
  final ApiClient apiClient;

  BookingApiService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<BookingModel>>> getUserBookings() async {
    try {
      final response = await _dio.get("/bookings");

      return handleApiResponse<List<BookingModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected booking list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              print("Invalid booking item");
              throw FormatException("Invalid booking item");
            }

            return BookingModel.fromJson(item);
          }).toList();
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
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<BookingModel>>> getOwnerBookings() async {
    try {
      final response = await _dio.get("/bookings/owner");

      return handleApiResponse<List<BookingModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected booking list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid booking item");
            }

            return BookingModel.fromJson(item);
          }).toList();
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
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
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
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> updateBookingStatus({
    required String id,
    String? status,
    String? workStatus,
  }) async {
    try {
      final response = await _dio.patch(
        "/bookings/$id/status",
        data: {"id": id, "status": ?status, "workStatus": ?workStatus},
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
    String? status,
    String? workStatus,
  }) async {
    try {
      final response = await _dio.patch(
        "/bookings/$id/workstatus",
        data: {"id": id, "status": ?status, "workStatus": ?workStatus},
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
}
