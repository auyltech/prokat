import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import '../models/auth_session.dart';

class AuthApiService {
  final Dio dio;

  AuthApiService(this.dio);

  Future<ApiResponse<AuthSession>> refreshSession() async {
    try {
      final response = await dio.post('/auth/session/refresh');

      return handleApiResponse<AuthSession>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic>) {
            throw FormatException("Invalid session item");
          }

          return AuthSession.fromJson(data);
        },
        fallbackMessage: "Failed to refresh session",
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

  Future<ApiResponse<void>> requestOtp(String phone) async {
    try {
      final response = await dio.post(
        '/auth/otp',
        data: {"phoneNumber": phone},
      );

      return handleEmptyApiResponse(response: response);
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

  Future<ApiResponse<AuthSession>> verifyOtp(String phone, String otp) async {
    try {
      final response = await dio.post(
        '/auth/otp/verify',
        data: {"phoneNumber": phone, "otp": otp},
      );

      return handleApiResponse<AuthSession>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic>) {
            throw FormatException("Invalid session item");
          }

          return AuthSession.fromJson(data);
        },
        fallbackMessage: "Failed to verify OTP",
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

  Future<ApiResponse<void>> logout() async {
    try {
      final response = await dio.post('/auth/logout');

      return handleEmptyApiResponse(response: response);
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
