import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';

class BookingApiService {
  final ApiClient apiClient;

  BookingApiService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<BookingModel>>> getUserBookings() async {
    try {
      final res = await _dio.get("/bookings");

      if (res.statusCode == 200) {
        final raw = res.data["data"] as List;

        final data = raw.map((e) => BookingModel.fromJson(e)).toList();

        return ApiResponse.success(data);
      }

      final message = extractBackendMessage(res.data);

      throw Exception(message);
    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid information";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      } else if (e.response?.data != null) {
        message = extractBackendMessage(e.response?.data);
      }

      return ApiResponse.failure(
        message: message, // real backend message: extractBackendMessage(e)
        error: e.response?.data?["error"].toString(),
      );
    } catch (e) {
      print(e);
      return ApiResponse.failure(
        message: "GetUserBookings_Unexpected_Error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<BookingModel>>> getOwnerBookings() async {
    try {
      final res = await _dio.get("/bookings/owner");

      if (res.statusCode == 200) {
        final data = res.data["data"] as List;
        final jsonData = data.map((e) => BookingModel.fromJson(e)).toList();

        return ApiResponse.success(jsonData);
      }

      final message = extractBackendMessage(res.data);

      throw Exception(message);
    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid information";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      } else if (e.response?.data != null) {
        message = extractBackendMessage(e.response?.data);
      }

      return ApiResponse.failure(
        message: message,
        error: e.response?.data?["error"]?.toString(),
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "GetOwnerBookings_Unexpected_error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<BookingModel?>> createBooking(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post("/bookings", data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(null);
      }

      final message = extractBackendMessage(response.data);

      throw Exception(message);
    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid information";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      } else if (e.response?.data != null) {
        message = extractBackendMessage(e.response?.data);
      }

      return ApiResponse.failure(
        message: message,
        error: e.response?.data?["error"]?.toString(),
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "CreateBooking_Unexpected_error",
        error: e.toString(),
      );
    }
  }

  Future<bool> updateBookingStatus({
    required String id,
    String? status,
    String? workStatus,
  }) async {
    try {
      final res = await _dio.patch(
        "/bookings/$id/status",
        data: {
          "id": id,
          if (status != null) "status": status,
          if (workStatus != null) "workStatus": workStatus,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateBookingWorkStatus({
    required String id,
    String? status,
    String? workStatus,
  }) async {
    try {
      final res = await _dio.patch(
        "/bookings/$id/workstatus",
        data: {
          "id": id,
          if (status != null) "status": status,
          if (workStatus != null) "workStatus": workStatus,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }
}
