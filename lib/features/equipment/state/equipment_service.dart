import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import '../../../core/constants/api_routes.dart';
import '../models/equipment_model.dart';

class EquipmentService {
  final ApiClient apiClient;

  EquipmentService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<List<Equipment>> getClientEquipment({
    String? categoryId,
    String? query,
    String? city,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiRoutes.equipment,
        queryParameters: {
          if (query?.isNotEmpty ?? false) 'query': query,
          if (city?.isNotEmpty ?? false) 'city': city,
          if (categoryId?.isNotEmpty ?? false) 'categoryId': categoryId,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data["data"] ?? [];
      return data.map((json) => Equipment.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.message ?? "Failed to fetch equipment";
    }
  }

  Future<List<Equipment>> getRenterEquipment({
    String? categoryId,
    String? query,
    String? city,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _dio.get(
        ApiRoutes.equipment,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (city != null && city.isNotEmpty) 'city': city,
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data["data"];

      if (data is! List) {
        return <Equipment>[];
      }

      final parsed = data
          .whereType<Map<String, dynamic>>() // safety check
          .map((json) => Equipment.fromJson(json))
          // .where(
          //   (e) =>
          //       e.isVisible &&
          //       e.location != null &&
          //       e.location?.latitude != null &&
          //       e.location?.longitude != null,
          // )
          .toList();

      return parsed;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<List<Equipment>> getOwnerEquipment() async {
    try {
      final response = await _dio.get(ApiRoutes.ownerEquipment);

      final List data = response.data["data"];

      return data.map((e) => Equipment.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Failed to load equipment');
    }
  }

  Future<Equipment> createEquipment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiRoutes.equipment, data: data);

      return Equipment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Failed to create equipment');
    }
  }

  Future<Equipment?> updateEquipment(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch('/equipment/$equipmentId', data: data);

      return Equipment.fromJson(response.data['data']);
    } on DioException catch (_) {
      return null;
      // throw Exception(e.response?.data ?? 'Failed to update equipment');
    } catch (e) {
      return null;
    }
  }

  Future<Equipment?> updateEquipmentLocation(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/location',
        data: data,
      );

      return Equipment.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Failed to update equipment');
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateEquipmentCategory({
    required String equipmentId,
    required String categoryId,
  }) async {
    try {
      final res = await _dio.patch(
        '/equipment/$equipmentId/category',
        data: {"id": equipmentId, "categoryId": categoryId},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
        // return RequestModel.fromJson(res.data['data']);
      }

      return false;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data ?? 'Failed to update equipment');
      }
      return false;
    }
  }

  Future<bool> updateVisibilityStatus(
    String equipmentId,
    bool isVisible,
    String status,
  ) async {
    try {
      final res = await _dio.patch(
        '/equipment/$equipmentId/status',
        data: {"id": equipmentId, "isVisible": isVisible, "status": status},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data ?? 'Failed to update equipment');
      }
      return false;
    }
  }

  Future<void> deleteEquipment(String equipmentId) async {
    try {
      await _dio.delete('/equipment/$equipmentId');
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Failed to delete equipment');
    }
  }

  Future<void> addPriceEntry(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    await _dio.post("/equipment/$equipmentId/priceEntry", data: data);
  }

  Future<void> updatePriceEntry(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    final priceEntryId = data["id"];

    await _dio.patch(
      '/equipment/$equipmentId/priceEntry/$priceEntryId',
      data: data,
    );
  }

  Future<void> deletePriceEntry(String equipmentId, String priceEntryId) async {
    try {
      await _dio.delete('/equipment/$equipmentId/priceEntry/$priceEntryId');
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Failed to delete price entry');
    }
  }
}
