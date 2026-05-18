import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/core/api/api_response.dart';
import '../../../core/constants/api_routes.dart';
import '../models/equipment_model.dart';
import 'dart:io';

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
      throw Exception(e.message ?? "Failed to fetch equipment");
    }
  }

  Future<ApiResponse<List<Equipment>?>> getRenterEquipment({
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data["data"];

        if (data is! List) {
          return ApiResponse.failure(
            message: extractBackendMessage(response.data),
          );
        }

        final parsed = data
            .whereType<Map<String, dynamic>>() // safety check
            .map((json) => Equipment.fromJson(json))
            .toList();

        return ApiResponse.success(parsed);
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
        message: message, // real backend message: extractBackendMessage(e)
        error: e.response?.data?["error"] ?? "Failed to load equipment",
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
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

  Future<ApiResponse<Equipment?>> getOwnerEquipmentById(String id) async {
    try {
      final response = await _dio.get("/equipment/owner/$id");

      final data = response.data["data"];

      return ApiResponse.success(
        data != null ? Equipment.fromJson(data) : null,
        message: "Equipment created successfully",
      );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> createEquipment(
    Map<String, dynamic> data,
  ) async {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> updateEquipment(
    Map<String, dynamic> data,
  ) async {
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
          "categoryId": data["cateogryId"],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(null, message: "Equipment saved");
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> updateEquipmentLocation(
    String equipmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/location',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> updateEquipmentCategory({
    required String equipmentId,
    required String categoryId,
  }) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/category',
        data: {"id": equipmentId, "categoryId": categoryId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> updateVisibilityStatus({
    required String equipmentId,
    required bool isVisible,
    required String status,
  }) async {
    try {
      final response = await _dio.patch(
        '/equipment/$equipmentId/status',
        data: {"id": equipmentId, "isVisible": isVisible, "status": status},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
      }

      final message = extractBackendMessage(response.data);

      throw Exception(message);
    } on DioException catch (e) {
      String message = "Something went wrong";

      message = extractBackendMessage(e.response?.data);

      return ApiResponse.failure(
        message: message,
        error: e.response?.data?["error"]?.toString(),
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> updateEquipmentSpecs(
    Map<String, dynamic> data,
  ) async {
    try {
      final equipmentId = data["equipmentId"] ?? "";
      final specs = data["specs"];

      final response = await _dio.patch(
        '/equipment/$equipmentId/specs',
        data: {"id": equipmentId, "specs": specs},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> deleteEquipment(String equipmentId) async {
    try {
      final response = await _dio.delete('/equipment/$equipmentId');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> createPriceEntry(
    Map<String, dynamic> data,
  ) async {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> updatePriceEntry(
    Map<String, dynamic> data,
  ) async {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> deletePriceEntry(
    Map<String, dynamic> data,
  ) async {
    try {
      final equipmentId = data["equipmentId"];
      final priceEntryId = data["id"];

      final response = await _dio.delete(
        '/equipment/$equipmentId/priceEntry/$priceEntryId',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Equipment created successfully",
        );
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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<Equipment?>> uploadEquipmentImage(
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(
          null,
          message: "Image Uploaded Successfully",
        );
      }

      // final payload = res.data;

      // final data = (payload is Map<String, dynamic>)
      //     ? (payload['data'] ?? payload)
      //     : payload;

      // if (data is Map<String, dynamic>) {
      //   // Preferred: updated equipment object
      //   if (data.containsKey('id') &&
      //       (data.containsKey('images') || data.containsKey('imageUrl'))) {
      //     return (equipment: Equipment.fromJson(data), image: null);
      //   }

      //   // Alternative: new image record
      //   if (data.containsKey('url')) {
      //     return (equipment: null, image: EquipmentImage.fromJson(data));
      //   }
      // }

      // return (equipment: null, image: null);

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
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<Equipment?> deleteEquipmentImage(
    String equipmentId,
    String imageId,
  ) async {
    try {
      final res = await _dio.delete('/equipment/$equipmentId/images/$imageId');

      final payload = res.data;
      final data = (payload is Map<String, dynamic>)
          ? (payload['data'] ?? payload)
          : payload;

      if (data is Map<String, dynamic>) {
        return Equipment.fromJson(data);
      }

      return null;
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    } catch (_) {
      return null;
    }
  }

  Future<Equipment?> setPrimaryEquipmentImage(
    String equipmentId,
    String imageId,
  ) async {
    try {
      final res = await _dio.patch(
        '/equipment/$equipmentId/images/$imageId/primary',
      );

      final payload = res.data;
      final data = (payload is Map<String, dynamic>)
          ? (payload['data'] ?? payload)
          : payload;

      if (data is Map<String, dynamic>) {
        return Equipment.fromJson(data);
      }

      return null;
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    } catch (_) {
      return null;
    }
  }
}
