import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import '../../../core/constants/api_routes.dart';
import '../models/category.dart';

class CategoryService {
  final ApiClient apiClient;

  CategoryService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await _dio.get(ApiRoutes.categories);

      final List data = response.data["data"];

      final categories = data.map((json) => Category.fromJson(json)).toList();

      // categories.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

      return ApiResponse(success: true, data: categories);
    } catch (e) {
      return ApiResponse.failure(
        error: "Could not load categories",
        message: "",
      );
    }
  }
}
