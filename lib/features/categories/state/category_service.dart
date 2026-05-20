import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import '../../../core/constants/api_routes.dart';
import '../models/category.dart';
import 'package:prokat/core/api/api_helper.dart';

class CategoryService {
  final ApiClient apiClient;

  CategoryService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await _dio.get(ApiRoutes.categories);

      return handleApiResponse<List<Category>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected category list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid category item");
            }

            return Category.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load categories",
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
