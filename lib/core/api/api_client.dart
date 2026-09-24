import 'dart:async';
import 'dart:convert';

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
      dio.interceptors.add(_DebugNetworkLogInterceptor());
    }
  }
}

class _DebugNetworkLogInterceptor extends Interceptor {
  static const _startedAtKey = 'debugNetworkLogStartedAt';
  static const _bodyLogLimit = 12000;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = Stopwatch()..start();
    Logger.log('[HTTP] --> ${options.method} ${options.uri}');
    if (options.queryParameters.isNotEmpty) {
      Logger.log('[HTTP]     query=${options.queryParameters}');
    }
    _logBody('requestBody', options.data);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final elapsed = _elapsed(response.requestOptions);
    Logger.log(
      '[HTTP] <-- ${response.statusCode} '
      '${response.requestOptions.method} ${response.requestOptions.uri}'
      '$elapsed',
    );
    _logBody('responseBody', response.data);
    _logKnownPayloadSummary(response.requestOptions.path, response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final elapsed = _elapsed(err.requestOptions);
    Logger.log(
      '[HTTP] <-- ERROR ${err.type} '
      '${err.requestOptions.method} ${err.requestOptions.uri}'
      '$elapsed message=${err.message}',
    );
    if (err.response != null) {
      final responseData = err.response?.data;
      _logBody('errorBody', responseData);
      _logKnownPayloadSummary(err.requestOptions.path, responseData);
    }
    handler.next(err);
  }

  String _elapsed(RequestOptions options) {
    final timer = options.extra[_startedAtKey];
    if (timer is! Stopwatch) return '';
    timer.stop();
    return ' ${timer.elapsedMilliseconds}ms';
  }

  void _logBody(String label, dynamic body) {
    if (body == null) return;
    Logger.log('[HTTP]     $label=${_formatBody(body)}');
  }

  String _formatBody(dynamic body) {
    if (body is FormData) {
      return _formatFormData(body);
    }
    if (body is MultipartFile) {
      return _formatMultipartFile(body);
    }
    if (body is Uint8List) {
      return 'binary(${body.length} bytes)';
    }
    if (body is Stream) {
      return 'stream(${body.runtimeType})';
    }

    final formatted = _tryFormatJson(body) ?? body.toString();
    return _truncate(formatted);
  }

  String? _tryFormatJson(dynamic body) {
    if (body is Map || body is List) {
      try {
        return jsonEncode(body);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatFormData(FormData body) {
    final fields = body.fields
        .map((field) => '${field.key}=${_truncate(field.value)}')
        .join(', ');
    final files = body.files
        .map((entry) {
          return '${entry.key}=${_formatMultipartFile(entry.value)}';
        })
        .join(', ');

    final parts = <String>[
      'fields=${body.fields.length}',
      if (fields.isNotEmpty) '[$fields]',
      'files=${body.files.length}',
      if (files.isNotEmpty) '[$files]',
    ];
    return 'FormData(${parts.join(', ')})';
  }

  String _formatMultipartFile(MultipartFile file) {
    final filename = file.filename;
    final name = filename == null || filename.isEmpty
        ? ''
        : ' filename=$filename';
    return 'MultipartFile(length=${file.length}$name)';
  }

  String _truncate(String value) {
    if (value.length <= _bodyLogLimit) return value;
    return '${value.substring(0, _bodyLogLimit)}... truncated';
  }

  void _logKnownPayloadSummary(String path, dynamic body) {
    if (path == '/catalog') {
      _logCatalogSummary(body);
      return;
    }
    if (path == '/equipment-demand/config') {
      _logDemandConfigSummary(body);
    }
  }

  void _logCatalogSummary(dynamic body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) return;

    final categories = data['categories'];
    if (categories is! List) return;

    final userVisible = categories.where((item) {
      return item is Map && _asBool(item['isUserVisible'], fallback: true);
    }).length;
    final ownerVisible = categories.where((item) {
      return item is Map && _asBool(item['isOwnerVisible'], fallback: true);
    }).length;

    Logger.log(
      '[HTTP]     catalog version=${data['version']} '
      'categories=${categories.length} '
      'userVisible=$userVisible ownerVisible=$ownerVisible',
    );
  }

  void _logDemandConfigSummary(dynamic body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) return;

    final enabled = data['enabled'] == true;
    final campaignId = data['campaignId']?.toString() ?? '';
    final hasResponded = data['hasResponded'] == true;
    final shouldShow = enabled && campaignId.isNotEmpty && !hasResponded;

    Logger.log(
      '[HTTP]     demandConfig enabled=$enabled '
      'campaignId=$campaignId hasResponded=$hasResponded '
      'shouldShow=$shouldShow',
    );
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }
}
