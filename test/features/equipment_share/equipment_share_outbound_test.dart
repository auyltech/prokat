import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_outbound.dart';
import 'package:share_plus/share_plus.dart';

import '../../helpers/recording_analytics_client.dart';

const _token = 'AbCdEfGhIjKlMnOpQr_-12';
const _retryToken = 'ZyXwVuTsRqPoNmLkJi_-98';

class _RegistryAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Future<ResponseBody> Function(RequestOptions)? respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (respond != null) return respond!(options);
    return _json(201, {
      'success': true,
      'data': options.path.endsWith('/links')
          ? options.data
          : {'recorded': true},
    });
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, Object?> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _Harness {
  final adapter = _RegistryAdapter();
  final client = RecordingAnalyticsClient();
  final sharedUrls = <String>[];
  late final api = EquipmentShareEventsApi(
    Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter,
  );

  Future<void> share({
    String token = _token,
    bool authenticated = true,
    ShareResult result = const ShareResult(
      'com.whatsapp',
      ShareResultStatus.success,
    ),
    Future<ShareResult?> Function(String)? sheet,
  }) => shareRegisteredEquipment(
    equipmentId: 'equipment-1',
    api: api,
    analytics: AnalyticsService(client),
    isAuthenticated: authenticated,
    newShareId: () => token,
    openShareSheet:
        sheet ??
        (url) async {
          sharedUrls.add(url);
          return result;
        },
  );
}

void main() {
  test(
    'registration acknowledgement precedes sheet; success tracks once',
    () async {
      final h = _Harness();
      final registration = Completer<ResponseBody>();
      h.adapter.respond = (request) async => request.path.endsWith('/links')
          ? registration.future
          : _json(201, {
              'success': true,
              'data': {'recorded': true},
            });
      final sharing = h.share();
      await pumpEventQueue();
      expect(h.adapter.requests.single.path, '/equipment-shares/links');
      expect(h.adapter.requests.single.data, {
        'equipmentId': 'equipment-1',
        'shareId': _token,
      });
      expect(h.sharedUrls, isEmpty);
      expect(h.client.events, isEmpty);
      registration.complete(
        _json(201, {
          'success': true,
          'data': {'equipmentId': 'equipment-1', 'shareId': _token},
        }),
      );
      await sharing;
      await pumpEventQueue();
      expect(h.sharedUrls, ['https://prokat.auyltech.kz/e/$_token']);
      final uri = Uri.parse(h.sharedUrls.single);
      expect(uri.pathSegments, ['e', _token]);
      expect(uri.hasQuery, isFalse);
      expect(uri.toString(), isNot(contains('equipment-1')));
      expect(_token, hasLength(22));
      expect(h.adapter.requests.map((r) => r.path), [
        '/equipment-shares/links',
        '/equipment-shares/events',
      ]);
      expect((h.adapter.requests.last.data as Map)['type'], 'SHARED');
      expect((h.adapter.requests.last.data as Map)['shareId'], _token);
      expect(h.client.events.single.name, 'share');
    },
  );

  for (final failure in ['http', 'offline', 'token', 'equipment', 'body']) {
    test(
      '$failure registration failure propagates; no sheet or tracking',
      () async {
        final h = _Harness();
        h.adapter.respond = (request) async {
          if (failure == 'offline') {
            throw DioException.connectionError(
              requestOptions: request,
              reason: 'offline',
            );
          }
          return _json(failure == 'http' ? 503 : 201, {
            'success': failure != 'body',
            'data': {
              'shareId': failure == 'token' ? _retryToken : _token,
              'equipmentId': failure == 'equipment' ? 'other' : 'equipment-1',
            },
          });
        };
        await expectLater(h.share(), throwsA(anything));
        await pumpEventQueue();
        expect(h.sharedUrls, isEmpty);
        expect(h.client.events, isEmpty);
        expect(h.adapter.requests, hasLength(1));
      },
    );
  }

  test('retry registers its new token before sharing', () async {
    final h = _Harness();
    h.adapter.respond = (_) async => _json(503, {'success': false});
    await expectLater(h.share(), throwsA(anything));
    h.adapter.respond = null;
    await h.share(token: _retryToken);
    await pumpEventQueue();
    expect(h.sharedUrls, ['https://prokat.auyltech.kz/e/$_retryToken']);
    expect((h.adapter.requests[1].data as Map)['shareId'], _retryToken);
    expect(h.client.events, hasLength(1));
    expect((h.adapter.requests.last.data as Map)['shareId'], _retryToken);
  });

  for (final status in [
    ShareResultStatus.dismissed,
    ShareResultStatus.unavailable,
  ]) {
    test('$status registers but never tracks SHARED', () async {
      final h = _Harness();
      await h.share(result: ShareResult('', status));
      await pumpEventQueue();
      expect(h.adapter.requests, hasLength(1));
      expect(h.client.events, isEmpty);
    });
  }

  test(
    'guest success registers and logs share without authenticated SHARED',
    () async {
      final h = _Harness();
      await h.share(authenticated: false);
      await pumpEventQueue();
      expect(h.sharedUrls, hasLength(1));
      expect(h.adapter.requests.single.path, '/equipment-shares/links');
      expect(h.client.events, hasLength(1));
    },
  );

  test(
    'unmounted UI after registration aborts the sheet and tracking',
    () async {
      final h = _Harness();
      await h.share(sheet: (_) async => null);
      await pumpEventQueue();
      expect(h.sharedUrls, isEmpty);
      expect(h.client.events, isEmpty);
      expect(h.adapter.requests, hasLength(1));
    },
  );
}
