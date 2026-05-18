import 'package:dio/dio.dart';
import '../errors/api_exception.dart';
import 'api_response.dart';

/// Base repository to handle API requests safely
/// Converts Dio exceptions into ApiResponse errors
abstract class BaseRepository {
  Future<ApiResponse<T>> handleRequest<T>(
    Future<Response> Function() request,
    T Function(dynamic data) parser,
  ) async {
    try {
      final response = await request();

      final parsedData = parser(response.data);

      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      final error = ApiException.fromDio(e);

      return ApiResponse(success: false, error: error.message);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<T> execute<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } catch (e) {
      throw ApiException(message: "BaseRepository_Unexpected error");
    }
  }
}
