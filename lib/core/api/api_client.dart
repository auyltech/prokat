import 'package:dio/dio.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import '../config/env.dart';
import 'api_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(AuthSecureStorage secureStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(ApiInterceptor(secureStorage));

    // Log api requests / responses
    // dio.interceptors.add(
    //   LogInterceptor(
    //     request: true,
    //     requestBody: true,
    //     responseBody: true,
    //     error: true,
    //   ),
    // );
  }
}
