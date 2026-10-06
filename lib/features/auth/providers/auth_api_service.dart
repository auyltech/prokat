import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';

import '../models/auth_session.dart';
import '../models/otp_verification.dart';

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
            throw const FormatException("Invalid session item");
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
        error: (exception.data ?? error).toString(),
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
      return handleDioException<void>(error);
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<OtpVerification>> verifyOtp(
    String phone,
    String otp, {
    Map<String, Object?>? attribution,
  }) async {
    try {
      final data = <String, Object?>{"phoneNumber": phone, "otp": otp};
      if (attribution != null) {
        data["attribution"] = attribution;
      }

      final response = await dio.post('/auth/otp/verify', data: data);

      return handleApiResponse<OtpVerification>(
        response: response,
        parser: (data) {
          if (data is! Map<String, dynamic>) {
            throw const FormatException("Invalid session item");
          }

          return OtpVerification(
            session: AuthSession.fromJson(data),
            isNewUser: data['isNewUser'] == true,
          );
        },
        fallbackMessage: "Failed to verify OTP",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: (exception.data ?? error).toString(),
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
        error: (exception.data ?? error).toString(),
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
