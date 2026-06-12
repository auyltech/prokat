import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';

class FavoriteService {
  final ApiClient apiClient;

  FavoriteService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<Equipment>>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites');

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
        fallbackMessage: "Failed to load favorites",
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

  Future<ApiResponse<void>> toggleFavorite(String equipmentId) async {
    try {
      final response = await _dio.post(
        '/favorites/toggle',
        data: {'equipmentId': equipmentId},
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Favorite item saved",
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
