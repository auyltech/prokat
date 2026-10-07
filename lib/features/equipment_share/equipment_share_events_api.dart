import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:uuid/uuid.dart';

/// Best-effort share ledger writes: errors are swallowed, nothing is retried.
class EquipmentShareEventsApi {
  EquipmentShareEventsApi(this._dio, {String Function()? newEventId})
    : _newEventId = newEventId ?? const Uuid().v4;

  final Dio _dio;
  final String Function() _newEventId;

  Future<void> recordShared({
    required String shareId,
    required String equipmentId,
    required String method,
  }) => _post({
    'type': 'SHARED',
    'shareId': shareId,
    'equipmentId': equipmentId,
    'method': method,
  });

  /// [openVia] is the backend wire value: `APP_LINK` or `INSTALL_REFERRER`.
  Future<void> recordOpened({
    required String equipmentId,
    String? shareId,
    required String openVia,
    required bool firstShareBootstrapRun,
  }) => _post({
    'type': 'OPENED',
    'shareId': ?shareId,
    'equipmentId': equipmentId,
    'openVia': openVia,
    'firstShareBootstrapRun': firstShareBootstrapRun,
  });

  Future<void> _post(Map<String, Object> body) async {
    try {
      await _dio.post<void>(
        ApiRoutes.equipmentShareEvents,
        data: {'clientEventId': _newEventId(), ...body},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (_) {}
  }
}

final equipmentShareEventsApiProvider = Provider<EquipmentShareEventsApi>(
  (ref) => EquipmentShareEventsApi(ref.watch(dioProvider)),
);
