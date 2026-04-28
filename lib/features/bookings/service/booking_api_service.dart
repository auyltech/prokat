import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';

class BookingApiService {
  final ApiClient apiClient;

  BookingApiService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<List<BookingModel>> getUserBookings() async {
    try {
      final res = await _dio.get("/bookings");

      return (res.data["data"] as List)
          .map((e) => BookingModel.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BookingModel>> getOwnerBookings() async {
    try {
      final res = await _dio.get("/bookings/owner");

      return (res.data["data"] as List)
          .map((e) => BookingModel.fromJson(e))
          .toList();
          
    } catch (e) {
      return [];
    }
  }

  Future<bool> createBooking(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post("/bookings", data: data);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException) {
        print("❌ DIO ERROR: ${e.message}");
        print("❌ STATUS: ${e.response?.statusCode}");
        print("❌ DATA: ${e.response?.data}");
      } else {
        print("❌ ERROR: $e");
      }
      return false;
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
          "status": ?status,
          "workStatus": ?workStatus,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
        // return BookingModel.fromJson(res.data["data"]);
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }
}
