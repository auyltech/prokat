import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_bootstrap.dart';
import 'package:prokat/features/equipment_share/equipment_share_events_api.dart';
import 'package:prokat/features/equipment_share/equipment_share_first_touch.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_open_recorder.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';

import '../../helpers/recording_analytics_client.dart';

const _shareId = 'AbCdEfGhIjKlMnOpQr_-12';
const _linksMethod = MethodChannel('com.llfbandit.app_links/messages');
const _linksEvents = EventChannel('com.llfbandit.app_links/events');
const _referrerChannel = MethodChannel(
  'com.chunkytofustudios.play_install_referrer',
);

String _key(String name) => Env.isLocal ? 'local_$name' : name;

String _shareUrl(String id, {String? shareId}) =>
    'https://prokat-bfbec.web.app/e/$id${shareId == null ? '' : '?s=$shareId'}';

AppStartupStatus _status(AppStartupRouteState route) => AppStartupStatus(
  routeState: route,
  step: AppStartupStep.done,
  progress: 1,
  stepLabel: '',
);

class _FakeStartup extends AppStartupController {
  _FakeStartup(Ref ref, AppStartupRouteState route)
    : super(ref, AppModeStorage()) {
    state = _status(route);
  }

  void setRoute(AppStartupRouteState route) => state = _status(route);
}

class _RecordingRecorder extends ShareOpenRecorder {
  _RecordingRecorder()
    : super(
        analytics: AnalyticsService(RecordingAnalyticsClient()),
        api: EquipmentShareEventsApi(Dio()),
        firstTouch: EquipmentShareFirstTouchStore(),
        isAuthenticated: () => false,
      );

  final opens = <EquipmentShareOpen>[];

  @override
  Future<void> record(EquipmentShareOpen open) async => opens.add(open);
}

class _Harness {
  _Harness(this.container, this.recorder, this.router, this.events);

  final ProviderContainer container;
  final _RecordingRecorder recorder;
  final GoRouter router;
  final MockStreamHandlerEventSink? Function() events;

  _FakeStartup get startup =>
      container.read(appStartupProvider.notifier) as _FakeStartup;

  EquipmentShareStorage get storage => EquipmentShareStorage();
}

Future<_Harness> _start(
  WidgetTester tester, {
  String? initialLink,
  String referrer = 'utm_source=google-play&utm_medium=organic',
  AppStartupRouteState route = AppStartupRouteState.client,
  Map<String, String> storage = const {},
}) async {
  FlutterSecureStorage.setMockInitialValues(Map.of(storage));

  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    _linksMethod,
    (call) async => call.method == 'getInitialLink' ? initialLink : null,
  );
  MockStreamHandlerEventSink? sink;
  messenger.setMockStreamHandler(
    _linksEvents,
    MockStreamHandler.inline(
      onListen: (_, events) {
        sink = events;
      },
    ),
  );
  messenger.setMockMethodCallHandler(
    _referrerChannel,
    (call) async => {
      'installReferrer': referrer,
      'referrerClickTimestampSeconds': 0,
      'installBeginTimestampSeconds': 0,
      'referrerClickTimestampServerSeconds': 0,
      'installBeginTimestampServerSeconds': 0,
      'installVersion': null,
      'googlePlayInstantParam': false,
    },
  );
  addTearDown(() {
    messenger.setMockMethodCallHandler(_linksMethod, null);
    messenger.setMockStreamHandler(_linksEvents, null);
    messenger.setMockMethodCallHandler(_referrerChannel, null);
  });

  final router = GoRouter(
    initialLocation: AppRoutes.main,
    routes: [
      GoRoute(
        path: AppRoutes.main,
        builder: (_, _) => const Scaffold(body: Text('Main')),
      ),
      GoRoute(
        path: '/e/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Share ${state.pathParameters['id']}')),
      ),
    ],
  );
  final recorder = _RecordingRecorder();
  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(router),
      appStartupProvider.overrideWith((ref) => _FakeStartup(ref, route)),
      shareOpenRecorderProvider.overrideWithValue(recorder),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  container.read(equipmentShareBootstrapProvider);
  await tester.pumpAndSettle();

  return _Harness(container, recorder, router, () => sink);
}

void main() {
  testWidgets('initial app link preserves shareId', (tester) async {
    final h = await _start(
      tester,
      initialLink: _shareUrl('eq-1', shareId: _shareId),
    );

    final open = h.recorder.opens.single;
    expect(open.link.equipmentId, 'eq-1');
    expect(open.link.shareId, _shareId);
    expect(open.link.canonical.hasQuery, isFalse);
    expect(open.via, ShareOpenVia.appLink);
    expect(open.firstShareBootstrapRun, isTrue);
    expect(await h.storage.wasInstallReferrerChecked(), isTrue);
  });

  testWidgets('initial app link after an earlier run is not first run', (
    tester,
  ) async {
    final h = await _start(
      tester,
      initialLink: _shareUrl('eq-1', shareId: _shareId),
      storage: {_key('equipment_share_install_referrer_checked'): '1'},
    );

    final open = h.recorder.opens.single;
    expect(open.via, ShareOpenVia.appLink);
    expect(open.firstShareBootstrapRun, isFalse);
    expect(open.link.shareId, _shareId);
  });

  testWidgets('install referrer preserves shareId', (tester) async {
    final h = await _start(tester, referrer: 'id=eq-1&s=$_shareId');

    final open = h.recorder.opens.single;
    expect(open.link.equipmentId, 'eq-1');
    expect(open.link.shareId, _shareId);
    expect(open.via, ShareOpenVia.installReferrer);
    expect(open.firstShareBootstrapRun, isTrue);
    expect(find.text('Share eq-1'), findsOneWidget);
  });

  testWidgets('stream link is never a first run', (tester) async {
    final h = await _start(tester);
    expect(h.recorder.opens, isEmpty);

    h.events()!.success(_shareUrl('eq-2', shareId: _shareId));
    await tester.pumpAndSettle();

    final open = h.recorder.opens.single;
    expect(open.link.equipmentId, 'eq-2');
    expect(open.link.shareId, _shareId);
    expect(open.via, ShareOpenVia.appLink);
    expect(open.firstShareBootstrapRun, isFalse);
    expect(find.text('Share eq-2'), findsOneWidget);
  });

  testWidgets('pending open keeps shareId, via and first run', (tester) async {
    final h = await _start(
      tester,
      initialLink: _shareUrl('eq-1', shareId: _shareId),
      route: AppStartupRouteState.loading,
    );

    expect(h.recorder.opens, isEmpty);
    final pending = (await h.storage.readPendingOpen())!;
    expect(pending.link.shareId, _shareId);
    expect(pending.via, ShareOpenVia.appLink);
    expect(pending.firstShareBootstrapRun, isTrue);

    h.startup.setRoute(AppStartupRouteState.guest);
    await tester.pumpAndSettle();

    final open = h.recorder.opens.single;
    expect(open.link.equipmentId, 'eq-1');
    expect(open.link.shareId, _shareId);
    expect(open.via, ShareOpenVia.appLink);
    expect(open.firstShareBootstrapRun, isTrue);
    expect(await h.storage.readPendingOpen(), isNull);
    expect(find.text('Share eq-1'), findsOneWidget);
  });

  testWidgets('flush does not reclassify install referrer', (tester) async {
    final h = await _start(
      tester,
      referrer: 'id=eq-1&s=$_shareId',
      route: AppStartupRouteState.loading,
    );
    expect(h.recorder.opens, isEmpty);

    h.startup.setRoute(AppStartupRouteState.client);
    await tester.pumpAndSettle();

    final open = h.recorder.opens.single;
    expect(open.via, ShareOpenVia.installReferrer);
    expect(open.firstShareBootstrapRun, isTrue);
    expect(open.link.shareId, _shareId);
  });

  testWidgets('legacy pending uri flushes as app link', (tester) async {
    final h = await _start(
      tester,
      storage: {
        _key('equipment_share_pending_uri'): _shareUrl(
          'eq-1',
          shareId: _shareId,
        ),
        _key('equipment_share_install_referrer_checked'): '1',
      },
    );

    final open = h.recorder.opens.single;
    expect(open.via, ShareOpenVia.appLink);
    expect(open.firstShareBootstrapRun, isFalse);
    expect(open.link.shareId, _shareId);
  });

  testWidgets('overlapping startup notifications record pending once', (
    tester,
  ) async {
    final h = await _start(
      tester,
      initialLink: _shareUrl('eq-1', shareId: _shareId),
      route: AppStartupRouteState.loading,
    );

    h.startup.setRoute(AppStartupRouteState.guest);
    h.startup.setRoute(AppStartupRouteState.client);
    h.startup.setRoute(AppStartupRouteState.owner);
    await tester.pumpAndSettle();

    expect(h.recorder.opens, hasLength(1));
  });

  testWidgets('overlay consume and later notifications do not re-record', (
    tester,
  ) async {
    final h = await _start(tester);
    h.events()!.success(_shareUrl('eq-1', shareId: _shareId));
    await tester.pumpAndSettle();
    expect(h.recorder.opens, hasLength(1));
    expect(find.text('Share eq-1'), findsOneWidget);

    h.router.pop();
    await tester.pumpAndSettle();
    h.startup.setRoute(AppStartupRouteState.owner);
    await tester.pumpAndSettle();
    h.startup.setRoute(AppStartupRouteState.client);
    await tester.pumpAndSettle();

    expect(h.recorder.opens, hasLength(1));
    expect(find.text('Main'), findsOneWidget);
  });

  testWidgets('afterAuth overlay opens the card without recording', (
    tester,
  ) async {
    final h = await _start(
      tester,
      storage: {
        _key('equipment_share_overlay'): jsonEncode(
          const EquipmentShareOverlay(
            path: '/e/eq-3',
            afterAuth: true,
          ).toJson(),
        ),
        _key('equipment_share_install_referrer_checked'): '1',
      },
    );

    expect(find.text('Share eq-3'), findsOneWidget);
    expect(h.recorder.opens, isEmpty);
  });
}
