import 'package:dio/dio.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import '../config/env.dart';
import 'api_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(
    AuthSecureStorage secureStorage, {
    required void Function() onUnauthorized,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,

        // Let service methods receive backend errors normally.
        validateStatus: (status) {
          return status != null && status < 600;
        },
      ),
    );

    dio.interceptors.add(
      ApiInterceptor(secureStorage, onUnauthorized: onUnauthorized),
    );
  }
}
