import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_open_recorder.dart';

import '../../helpers/recording_analytics_client.dart';

const _shareId = 'AbCdEfGhIjKlMnOpQr_-12';
const _eventId = '6f1c2b9e-3d4a-4b7c-9e8f-0a1b2c3d4e5f';

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

class _RecordingFirstTouch extends NoopFirstTouch {
  _RecordingFirstTouch({this.fail = false});

  final bool fail;
  final saved = <EquipmentShareOpen>[];

  @override
  Future<void> saveIfEmpty(EquipmentShareOpen open) async {
    saved.add(open);
    if (fail) throw StateError('first touch failure');
  }
}

class _Harness {
  _Harness({
    bool authenticated = false,
    bool analyticsThrows = false,
    bool apiFails = false,
    bool firstTouchFails = false,
  }) : client = RecordingAnalyticsClient(throwOnCall: analyticsThrows),
       adapter = _StubAdapter(fail: apiFails),
       firstTouch = _RecordingFirstTouch(fail: firstTouchFails) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    recorder = ShareOpenRecorder(
      analytics: AnalyticsService(client),
      api: EquipmentShareEventsApi(dio, newEventId: () => _eventId),
      isAuthenticated: () => authenticated,
      firstTouch: firstTouch,
    );
  }

  final RecordingAnalyticsClient client;
  final _StubAdapter adapter;
  final _RecordingFirstTouch firstTouch;
  late final ShareOpenRecorder recorder;
}

EquipmentShareOpen _open({
  String? shareId = _shareId,
  ShareOpenVia via = ShareOpenVia.installReferrer,
  bool firstRun = true,
}) {
  final query = shareId == null ? '' : '?s=$shareId';
  return EquipmentShareOpen(
    link: EquipmentShareLink.tryParse(
      Uri.parse('https://prokat-bfbec.web.app/e/eq-1$query'),
    )!,
    via: via,
    firstShareBootstrapRun: firstRun,
  );
}

void main() {
  test('logs share_link_opened with via and first run', () async {
    final h = _Harness();

    await h.recorder.record(_open());

    expect(h.client.events.single.name, 'share_link_opened');
    expect(h.client.events.single.params, {
      'item_id': 'eq-1',
      'share_id': _shareId,
      'open_via': 'install_referrer',
      'first_share_bootstrap_run': 1,
    });
  });

  test('omits share_id when the link has none', () async {
    final h = _Harness();

    await h.recorder.record(
      _open(shareId: null, via: ShareOpenVia.appLink, firstRun: false),
    );

    expect(h.client.events.single.params, {
      'item_id': 'eq-1',
      'open_via': 'app_link',
      'first_share_bootstrap_run': 0,
    });
  });

  test('posts OPENED', () async {
    final h = _Harness();

    await h.recorder.record(_open());

    expect(h.adapter.requests, hasLength(1));
    expect(h.adapter.requests.single.path, '/equipment-shares/events');
    expect(h.adapter.requests.single.data, {
      'clientEventId': _eventId,
      'type': 'OPENED',
      'shareId': _shareId,
      'equipmentId': 'eq-1',
      'openVia': 'INSTALL_REFERRER',
      'firstShareBootstrapRun': true,
    });
  });

  test('api failure does not throw', () async {
    final h = _Harness(apiFails: true);

    await expectLater(h.recorder.record(_open()), completes);
    expect(h.client.events, hasLength(1));
    expect(h.firstTouch.saved, hasLength(1));
  });

  test('analytics failure does not suppress OPENED', () async {
    final h = _Harness(analyticsThrows: true);

    await expectLater(h.recorder.record(_open()), completes);
    expect(h.adapter.requests, hasLength(1));
    expect(h.firstTouch.saved, hasLength(1));
  });

  test('authenticated user does not write first touch', () async {
    final h = _Harness(authenticated: true);

    await h.recorder.record(_open());

    expect(h.firstTouch.saved, isEmpty);
    expect(h.client.events, hasLength(1));
    expect(h.adapter.requests, hasLength(1));
  });

  test('guest reaches the first-touch boundary', () async {
    final h = _Harness();
    final open = _open();

    await h.recorder.record(open);

    expect(h.firstTouch.saved, [same(open)]);
  });

  test('first-touch failure does not escape or block the others', () async {
    final h = _Harness(firstTouchFails: true);

    await expectLater(h.recorder.record(_open()), completes);
    expect(h.client.events, hasLength(1));
    expect(h.adapter.requests, hasLength(1));
  });

  test('all three failing still completes', () async {
    final h = _Harness(
      analyticsThrows: true,
      apiFails: true,
      firstTouchFails: true,
    );

    await expectLater(h.recorder.record(_open()), completes);
    expect(h.adapter.requests, hasLength(1));
    expect(h.firstTouch.saved, hasLength(1));
  });

  test('default first touch is a no-op', () async {
    await expectLater(const NoopFirstTouch().saveIfEmpty(_open()), completes);
  });
}
