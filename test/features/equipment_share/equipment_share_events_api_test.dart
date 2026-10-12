import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';

const _eventId = '6f1c2b9e-3d4a-4b7c-9e8f-0a1b2c3d4e5f';
const _shareId = 'AbCdEfGhIjKlMnOpQr_-12';

class _StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  _StubAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int statusCode, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

(EquipmentShareEventsApi, _StubAdapter) _api(
  ResponseBody Function(RequestOptions options) respond,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  final adapter = _StubAdapter(respond);
  dio.httpClientAdapter = adapter;
  return (EquipmentShareEventsApi(dio, newEventId: () => _eventId), adapter);
}

void main() {
  for (final recorded in [true, false]) {
    test(
      'OPENED stable eventId retry acknowledges recorded=$recorded',
      () async {
        final (api, adapter) = _api(
          (_) => _json(201, {
            'success': true,
            'data': {'recorded': recorded},
          }),
        );
        const id = '00000006-0000-4000-8000-000000000001';
        for (var attempt = 0; attempt < 2; attempt++) {
          expect(
            await api.recordOpened(
              equipmentId: 'eq-1',
              shareId: _shareId,
              openVia: 'APP_LINK',
              firstShareBootstrapRun: false,
              clientEventId: id,
            ),
            isTrue,
          );
        }
        expect(adapter.requests.map((r) => (r.data as Map)['clientEventId']), [
          id,
          id,
        ]);
      },
    );
  }

  test('malformed OPENED acknowledgement remains retryable', () async {
    final (api, _) = _api((_) => _json(201, {'success': true}));
    expect(
      await api.recordOpened(
        equipmentId: 'eq-1',
        openVia: 'APP_LINK',
        firstShareBootstrapRun: false,
      ),
      isFalse,
    );
  });

  test('posts SHARED body', () async {
    final (api, adapter) = _api(
      (_) => _json(201, {
        'success': true,
        'data': {'recorded': true},
      }),
    );

    await api.recordShared(
      shareId: _shareId,
      equipmentId: 'eq-1',
      method: 'whatsapp',
    );

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, ApiRoutes.equipmentShareEvents);
    expect(request.path, '/equipment-shares/events');
    expect(request.data, {
      'clientEventId': _eventId,
      'type': 'SHARED',
      'shareId': _shareId,
      'equipmentId': 'eq-1',
      'method': 'whatsapp',
    });
    expect(request.sendTimeout, const Duration(seconds: 10));
    expect(request.receiveTimeout, const Duration(seconds: 10));
  });

  test('posts OPENED body per contract', () async {
    final (api, adapter) = _api(
      (_) => _json(201, {
        'success': true,
        'data': {'recorded': true},
      }),
    );

    await api.recordOpened(
      equipmentId: 'eq-1',
      openVia: 'APP_LINK',
      firstShareBootstrapRun: false,
    );

    expect(adapter.requests.single.data, {
      'clientEventId': _eventId,
      'type': 'OPENED',
      'equipmentId': 'eq-1',
      'openVia': 'APP_LINK',
      'firstShareBootstrapRun': false,
    });
  });

  test('default clientEventId is a uuid v4', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final adapter = _StubAdapter((_) => _json(201, {'success': true}));
    dio.httpClientAdapter = adapter;

    await EquipmentShareEventsApi(dio)
        .recordShared(shareId: _shareId, equipmentId: 'eq-1', method: 'copy');

    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(
      body['clientEventId'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('swallows 404 without retry', () async {
    final (api, adapter) = _api(
      (_) => _json(404, {'success': false, 'message': 'Not found'}),
    );

    await expectLater(
      api.recordShared(shareId: _shareId, equipmentId: 'eq-1', method: 'copy'),
      completes,
    );
    expect(adapter.requests, hasLength(1));
  });

  test('swallows timeout without retry', () async {
    final (api, adapter) = _api(
      (options) => throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: options,
      ),
    );

    await expectLater(
      api.recordShared(shareId: _shareId, equipmentId: 'eq-1', method: 'copy'),
      completes,
    );
    expect(adapter.requests, hasLength(1));
  });
}
