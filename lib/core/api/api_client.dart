import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:prokat/core/services/client_request_metadata_service.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import '../config/env.dart';
import 'api_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(
    AuthSecureStorage secureStorage, {
    required ClientRequestMetadataService requestMetadata,
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
      ApiInterceptor(
        secureStorage,
        requestMetadata: requestMetadata,
        onUnauthorized: onUnauthorized,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: Logger.log,
        ),
      );
    }
  }
}
