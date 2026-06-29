import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import '../models/auth_session.dart';
import '../models/auth_credentials.dart';

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

  Future<ApiResponse<AuthSession>> loginWithCredentials(
    LoginCredentials credentials,
  ) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'username': credentials.username,
          'password': credentials.password,
        },
      );

      return handleApiResponse<AuthSession>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic>) {
            throw FormatException("Invalid session item");
          }

          return AuthSession.fromJson(data);
        },
        fallbackMessage: "Failed to login",
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

  Future<ApiResponse<AuthSession>> registerCredentials(
    RegisterCredentials credentials,
  ) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'firstName': credentials.firstName,
          'lastName': credentials.lastName,
          'username': credentials.username,
          'password': credentials.password,
        },
      );

      return handleApiResponse<AuthSession>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic>) {
            throw FormatException("Invalid session item");
          }

          return AuthSession.fromJson(data);
        },
        fallbackMessage: "Failed to create account",
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

  Future<ApiResponse<void>> forgotPassword(String usernameOrPhone) async {
    try {
      // TODO: implement or remove password
      final response = await dio.post(
        '/auth/forgot-password',
        data: {'identifier': usernameOrPhone},
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

  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      // TODO: implement or remove password
      final response = await dio.post(
        '/auth/reset-password',
        data: {'token': token, 'password': newPassword},
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

  Future<ApiResponse<void>> requestOtp(String phone) async {
    try {
      final response = await dio.post(
        '/auth/otp',
        data: {"phoneNumber": phone},
      );

      print(response);

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
