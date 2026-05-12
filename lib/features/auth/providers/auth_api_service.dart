import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/core/api/api_response.dart';
import '../models/auth_session.dart';
import '../models/auth_credentials.dart';

class AuthApiService {
  final Dio dio;

  AuthApiService(this.dio);

  Future<AuthSession?> refreshSession() async {
    try {
      late Response response;

      response = await dio.post('/auth/session/refresh');

      if (response.statusCode == 200) {
        return AuthSession.fromJson(response.data);
      }

      return null;
    } catch (e) {
      return null;
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

      if (response.statusCode == 200) {
        return ApiResponse.success(
          AuthSession.fromJson(response.data),
          message: "Account created successfully",
        );
      }

      final message = extractBackendMessage(response.data);

      throw Exception(message);
    } on DioException catch (e) {
      String message = "Something went wrong";
      // "Network error. Please try again."

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid credentials";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      } else if (e.response?.data != null) {
        message = extractBackendMessage(e.response?.data);
      }
      print("api service catch message: $message");

      return ApiResponse.failure(
        message: message, // real backend message: extractBackendMessage(e)
        error: e.response?.data?["error"].toString(),
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

      if (response.statusCode == 201) {
        return ApiResponse.success(
          AuthSession.fromJson(response.data),
          message: "Account created successfully",
        );
      } else {
        return ApiResponse.failure(error: "Something went wrong");
      }
    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid credentials";
      } else if (e.response?.statusCode == 409) {
        message = "Username already registered";
      } else if (e.response?.statusCode == 410) {
        message = "Wrong data";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      }

      return ApiResponse.failure(
        message: message, // real backend message: extractBackendMessage(e)
        error: e.response?.data?["error"].toString(),
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<void> forgotPassword(String usernameOrPhone) async {
    try {
      await dio.post(
        '/auth/forgot-password',
        data: {'identifier': usernameOrPhone},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await dio.post(
        '/auth/reset-password',
        data: {'token': token, 'password': newPassword},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> requestOtp(String phone) async {
    try {
      final response = await dio.post(
        '/auth/otp',
        data: {"phoneNumber": phone},
      );

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<ApiResponse<AuthSession>> verifyOtp(String phone, String otp) async {
    try {
      final response = await dio.post(
        '/auth/otp/verify',
        data: {"phoneNumber": phone, "otp": otp},
      );

      print(response.toString());

      if (response.statusCode == 200) {
        return ApiResponse.success(
          AuthSession.fromJson(response.data),
          message: "Verification successfull",
        );
      } else {
        final message = extractBackendMessage(response.data);
        print(message);
        return ApiResponse.failure(error: message);
      }
    } on DioException catch (e) {
      String message = "Something went wrong";

      print("DIO_ERROR");
      print(e.response?.statusCode);
      print(e.response?.data["message"]);
      print(e.response?.data["error"]);

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid credentials";
      }
      if (e.response?.statusCode == 401) {
        message = "Invalid OTP";
      } else if (e.response?.statusCode == 409) {
        message = "Username already registered";
      } else if (e.response?.statusCode == 410) {
        message = "Wrong data";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      }

      return ApiResponse.failure(
        message: message, // real backend message: extractBackendMessage(e)
        error: e.response?.data["error"],
      );
    } catch (e) {
      print("NOT_DIO_ERROR");
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await dio.post('/auth/logout');
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        return Exception(data['message']);
      }

      return Exception("Server error (${e.response?.statusCode})");
    }

    return Exception("Network error");
  }
}
