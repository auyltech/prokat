import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:dio/dio.dart';

class RequestService {
  final ApiClient apiClient;

  RequestService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<List<RequestModel>> getUserRequests() async {
    try {
      final res = await _dio.get('/requests');

      return (res.data['data'] as List)
          .map((e) => RequestModel.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RequestModel>> getOwnerRequests() async {
    try {
      final res = await _dio.get('/requests/owner');

      return (res.data['data'] as List)
          .map((e) => RequestModel.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> createRequest({
    required String categoryId,
    required String locationId,
    required String capacity,
    required DateTime requiredOn,
    DateTime? requiredAt,
    String? comment,
    required int offeredRate,
  }) async {
    try {
      final res = await _dio.post(
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

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
        // return RequestModel.fromJson(res.data['data']);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<RequestModel?> updateRequest({
    required String id,
    String? locationId,
    DateTime? requiredOn,
    DateTime? requiredAt,
    int? offeredRate,
  }) async {
    try {
      final res = await _dio.patch(
        '/requests/$id',
        data: {
          "locationId": ?locationId,
          if (requiredOn != null) "requiredOn": requiredOn.toIso8601String(),
          if (requiredAt != null) "requiredAt": requiredAt.toIso8601String(),
          "offeredRate": ?offeredRate,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return RequestModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelRequest(String id) async {
    try {
      final res = await _dio.patch(
        '/requests/$id/status',
        data: {"id": id, "status": "CANCELLED"},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectRequest(String id) async {
    try {
      final res = await _dio.patch(
        '/requests/$id/reject',
        data: {"id": id, "status": "REJECTED"},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
