import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_result.dart';
import 'package:share_plus/share_plus.dart';

import '../../helpers/recording_analytics_client.dart';

const _shareId = 'AbCdEfGhIjKlMnOpQr_-12';
const _eventId = '6f1c2b9e-3d4a-4b7c-9e8f-0a1b2c3d4e5f';
const _whatsApp = ShareResult(
  'com.whatsapp/com.whatsapp.contact.ContactPicker',
  ShareResultStatus.success,
);

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({this.fail = false});

  final bool fail;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (fail) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'recorded': true},
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Harness {
  _Harness({bool analyticsThrows = false, bool apiFails = false})
    : client = RecordingAnalyticsClient(throwOnCall: analyticsThrows),
      adapter = _StubAdapter(fail: apiFails) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    api = EquipmentShareEventsApi(dio, newEventId: () => _eventId);
  }

  final RecordingAnalyticsClient client;
  final _StubAdapter adapter;
  late final EquipmentShareEventsApi api;

  Future<void> report(ShareResult result, {required bool isAuthenticated}) {
    return reportShareResult(
      result: result,
      shareId: _shareId,
      equipmentId: 'eq-1',
      analytics: AnalyticsService(client),
      api: api,
      isAuthenticated: isAuthenticated,
    );
  }
}

void main() {
  test('success logs share and posts SHARED', () async {
    final h = _Harness();

    await h.report(_whatsApp, isAuthenticated: true);
    await pumpEventQueue();

    expect(h.client.events, hasLength(1));
    expect(h.client.events.single.name, 'share');
    expect(h.client.events.single.params, {
      'content_type': 'equipment',
      'item_id': 'eq-1',
      'share_id': _shareId,
      'method': 'whatsapp',
    });
    expect(h.adapter.requests, hasLength(1));
    expect(h.adapter.requests.single.data, {
      'clientEventId': _eventId,
      'type': 'SHARED',
      'shareId': _shareId,
      'equipmentId': 'eq-1',
      'method': 'whatsapp',
    });
  });

  test('dismissed logs nothing', () async {
    final h = _Harness();

    await h.report(
      const ShareResult('', ShareResultStatus.dismissed),
      isAuthenticated: true,
    );
    await pumpEventQueue();

    expect(h.client.events, isEmpty);
    expect(h.adapter.requests, isEmpty);
  });

  test('unavailable logs nothing', () async {
    final h = _Harness();

    await h.report(ShareResult.unavailable, isAuthenticated: true);
    await pumpEventQueue();

    expect(h.client.events, isEmpty);
    expect(h.adapter.requests, isEmpty);
  });

  test('guest success logs share without POST', () async {
    final h = _Harness();

    await h.report(
      const ShareResult(
        'com.apple.UIKit.activity.CopyToPasteboard',
        ShareResultStatus.success,
      ),
      isAuthenticated: false,
    );
    await pumpEventQueue();

    expect(h.client.events.single.name, 'share');
    expect(h.client.events.single.params['method'], 'copy');
    expect(h.adapter.requests, isEmpty);
  });

  test('analytics and api failures do not escape', () async {
    final h = _Harness(analyticsThrows: true, apiFails: true);

    await expectLater(h.report(_whatsApp, isAuthenticated: true), completes);
    await pumpEventQueue();

    expect(h.client.events, isEmpty);
    expect(h.adapter.requests, hasLength(1));
  });
}
