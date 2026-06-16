import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import '../../../core/constants/api_routes.dart';
import '../models/equipment_model.dart';
import 'dart:io';

class EquipmentService {
  final ApiClient apiClient;

  EquipmentService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<Equipment>>> getClientEquipment({
    String? categoryId,
    String? query,
    String? city,
    int page = 1,
    int itemsPerPage = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiRoutes.equipment,
        queryParameters: {
          if (query?.isNotEmpty ?? false) 'query': query,
          if (city?.isNotEmpty ?? false) 'city': city,
          if (categoryId?.isNotEmpty ?? false) 'categoryId': categoryId,
          'page': page,
          'itemsPerPage': itemsPerPage,
        },
      );

      return handleApiResponse<List<Equipment>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected equipment list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid equipment item");
            }

            return Equipment.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load equipment",
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

  Future<ApiResponse<List<Equipment>?>> getRenterEquipment({
    String? categoryId,
    String? query,
    String? city,
    int? page,
    int? itemsPerPage,
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
          'itemsPerPage': itemsPerPage,
        },
      );

      return handleApiResponse<List<Equipment>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected equipment list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid equipment item");
            }

            return Equipment.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load equipment",
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

  Future<ApiResponse<List<Equipment>>> getOwnerEquipment() async {
    try {
      final response = await _dio.get(ApiRoutes.ownerEquipment);

      return handleApiResponse<List<Equipment>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected equipment list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid equipment item");
            }

            return Equipment.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load equipment",
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

  Future<ApiResponse<Equipment?>> getOwnerEquipmentById(String id) async {
    try {
      final response = await _dio.get("/equipment/owner/$id");

      return handleApiResponse<Equipment>(
        response: response,
        parser: (data) => Equipment.fromJson(data),
        fallbackMessage: "Failed to load equipment",
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

  Future<ApiResponse<void>> createEquipment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiRoutes.equipment,
        data: {
          "name": data["name"],
          "model": data["model"] ?? "",
          "plateNumber": data["plateNumber"] ?? "",
          "city": data["city"],
          "categoryId": data["categoryId"],
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Equipment created successfully",
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

  Future<ApiResponse<void>> updateEquipment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '/equipment/${data["id"]}',
        data: {
          "id": data["id"],
          "name": data["name"],
          "model": data["model"] ?? "",
          "plateNumber": data["plateNumber"] ?? "",
          "ownerComment": data["ownerComment"],
          "rentCondition": data["rentCondition"],
          "city": data["city"],
          "categoryId": data["categoryId"],
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Equipment updated successfully",
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

  Future<ApiResponse<void>> updateEquipmentLocation(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/location',
        data: data,
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Equipment updated successfully",
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

  Future<ApiResponse<void>> updateEquipmentCategory({
    required String equipmentId,
    required String categoryId,
  }) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/category',
        data: {"id": equipmentId, "categoryId": categoryId},
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Equipment updated successfully",
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

  Future<ApiResponse<void>> updateVisibilityStatus({
    required String equipmentId,
    required bool isVisible,
    required EquipmentStatus status,
  }) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/status',
        data: {
          "id": equipmentId,
          "isVisible": isVisible,
          "status": status.name.toUpperCase(),
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Equipment updated successfully",
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

  Future<ApiResponse<void>> updateEquipmentSpecs(
    Map<String, dynamic> data,
  ) async {
    try {
      final equipmentId = data["equipmentId"] ?? "";
      final specs = data["specs"];

      final response = await _dio.patch(
        '/equipment/$equipmentId/specs',
        data: {"id": equipmentId, "specs": specs},
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Equipment updated successfully",
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

  Future<ApiResponse<void>> deleteEquipment(String equipmentId) async {
    try {
      final response = await _dio.delete('/equipment/$equipmentId');

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Equipment updated successfully",
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

  Future<ApiResponse<void>> createPriceEntry(Map<String, dynamic> data) async {
    try {
      final equipmentId = data["equipmentId"];
      final price = data["price"];
      final priceRate = data["priceRate"];
      final serviceTime = data["serviceTime"];

      final response = await _dio.post(
        "/equipment/$equipmentId/priceEntry",
        data: {
          "equipmentId": equipmentId,
          "price": price,
          "priceRate": priceRate,
          "serviceTime": serviceTime,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Price entry created successfully",
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

  Future<ApiResponse<void>> updatePriceEntry(Map<String, dynamic> data) async {
    try {
      final equipmentId = data["equipmentId"];
      final priceEntryId = data["id"];
      final price = data["price"];
      final priceRate = data["priceRate"];
      final serviceTime = data["serviceTime"];

      final response = await _dio.patch(
        '/equipment/$equipmentId/priceEntry/$priceEntryId',
        data: {
          "equipmentId": equipmentId,
          "priceEntryId": priceEntryId,
          "price": price,
          "priceRate": priceRate,
          "serviceTime": serviceTime,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Price entry updated successfully",
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

  Future<ApiResponse<void>> deletePriceEntry(Map<String, dynamic> data) async {
    try {
      final equipmentId = data["equipmentId"];
      final priceEntryId = data["id"];

      final response = await _dio.delete(
        '/equipment/$equipmentId/priceEntry/$priceEntryId',
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Price entry deleted successfully",
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

  Future<ApiResponse<void>> uploadEquipmentImage(
    String equipmentId,
    File imageFile,
  ) async {
    try {
      final fileName = imageFile.path.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'equipmentImage': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        "type": "equipment",
      });

      final response = await _dio.post(
        '/equipment/$equipmentId/images',
        data: formData,
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Image uploaded",
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

  Future<ApiResponse<void>> deleteEquipmentImage(
    String equipmentId,
    String imageId,
  ) async {
    try {
      final response = await _dio.delete(
        '/equipment/$equipmentId/images/$imageId',
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Image deleted",
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

  Future<ApiResponse<void>> setPrimaryEquipmentImage(
    String equipmentId,
    String imageId,
  ) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/images/$imageId/primary',
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Image updated",
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
