import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:uuid/uuid.dart';

/// Best-effort ledger transport; durable OPENED retry belongs to share ingress.
class EquipmentShareEventsApi {
  EquipmentShareEventsApi(this._dio, {String Function()? newEventId})
    : _newEventId = newEventId ?? const Uuid().v4;

  final Dio _dio;
  final String Function() _newEventId;

  Future<void> recordShared({
    required String shareId,
    required String equipmentId,
    required String method,
  }) async {
    await _post({
      'type': 'SHARED',
      'shareId': shareId,
      'equipmentId': equipmentId,
      'method': method,
    });
  }

  /// [openVia] is the backend wire value: `APP_LINK` or `INSTALL_REFERRER`.
  Future<bool> recordOpened({
    required String equipmentId,
    String? shareId,
    required String openVia,
    required bool firstShareBootstrapRun,
    String? clientEventId,
  }) => _post({
    'type': 'OPENED',
    'shareId': ?shareId,
    'equipmentId': equipmentId,
    'openVia': openVia,
    'firstShareBootstrapRun': firstShareBootstrapRun,
  }, clientEventId: clientEventId);

  Future<bool> _post(Map<String, Object> body, {String? clientEventId}) async {
    final cancellation = CancelToken();
    try {
      final response = await _dio
          .post<Object?>(
            ApiRoutes.equipmentShareEvents,
            data: {'clientEventId': clientEventId ?? _newEventId(), ...body},
            cancelToken: cancellation,
            options: Options(
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          )
          .timeout(const Duration(seconds: 10));
      final data = response.data;
      return (response.statusCode == 200 || response.statusCode == 201) &&
          data is Map &&
          data['success'] == true &&
          data['data'] is Map &&
          (data['data'] as Map)['recorded'] is bool;
    } on TimeoutException {
      cancellation.cancel();
      return false;
    } catch (_) {
      return false;
    }
  }
}

final equipmentShareEventsApiProvider = Provider<EquipmentShareEventsApi>(
  (ref) => EquipmentShareEventsApi(ref.watch(dioProvider)),
);
