import 'dart:async';
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
import 'package:prokat/features/equipment_share/equipment_share_resolver.dart';

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

class _Resolver extends EquipmentShareResolver {
  _Resolver(this.reply) : super(Dio());
  final Future<ShareResolution> Function(String) reply;
  final calls = <String>[];

  @override
  Future<ShareResolution> resolve(String id) {
    calls.add(id);
    return reply(id);
  }
}

Future<_Harness> _start(
  WidgetTester tester, {
  String? initialLink,
  String referrer = 'utm_source=google-play&utm_medium=organic',
  AppStartupRouteState route = AppStartupRouteState.client,
  Map<String, String> storage = const {},
  _Resolver? resolver,
  Future<String?>? initialReply,
}) async {
  FlutterSecureStorage.setMockInitialValues(Map.of(storage));

  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    _linksMethod,
    (call) async => call.method == 'getInitialLink'
        ? await (initialReply ?? Future.value(initialLink))
        : null,
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
      if (resolver != null)
        equipmentShareResolverProvider.overrideWithValue(resolver),
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
  testWidgets(
    'full registry URI from existing Install Referrer uses same resolver',
    (tester) async {
      final resolver = _Resolver(
        (_) async =>
            const ShareResolution(ShareResolutionStatus.resolved, 'eq-1'),
      );
      final h = await _start(
        tester,
        referrer: 'https://open.prokat.auyltech.kz/e/$_shareId',
        resolver: resolver,
      );
      expect(resolver.calls, [_shareId]);
      expect(h.recorder.opens.single.link.shareId, _shareId);
      expect(h.recorder.opens.single.via, ShareOpenVia.installReferrer);
      expect(find.text('Share eq-1'), findsOneWidget);
    },
  );

  testWidgets(
    'persisted pending and initial delivery of same token are accepted once',
    (tester) async {
      const uri = 'https://open.prokat.auyltech.kz/e/$_shareId';
      final resolver = _Resolver(
        (_) async =>
            const ShareResolution(ShareResolutionStatus.resolved, 'eq-1'),
      );
      final h = await _start(
        tester,
        initialLink: uri,
        resolver: resolver,
        storage: {
          _key('equipment_share_pending_uri'): jsonEncode({
            'v': 2,
            'uri': uri,
            'via': 'app_link',
            'firstShareBootstrapRun': false,
          }),
        },
      );
      expect(h.recorder.opens, hasLength(1));
      expect(resolver.calls, [_shareId]);
      expect(find.text('Share eq-1'), findsOneWidget);
    },
  );

  testWidgets('late initial link cannot replace a newer runtime delivery', (
    tester,
  ) async {
    final initial = Completer<String?>();
    final resolver = _Resolver(
      (_) async =>
          const ShareResolution(ShareResolutionStatus.resolved, 'eq-new'),
    );
    final h = await _start(
      tester,
      initialReply: initial.future,
      resolver: resolver,
    );
    h.events()!.success(
      'https://open.prokat.auyltech.kz/e/ZyXwVuTsRqPoNmLkJi_-98',
    );
    await tester.pumpAndSettle();
    initial.complete('https://open.prokat.auyltech.kz/e/$_shareId');
    await tester.pumpAndSettle();
    expect(resolver.calls, ['ZyXwVuTsRqPoNmLkJi_-98']);
    expect(h.recorder.opens.single.link.shareId, 'ZyXwVuTsRqPoNmLkJi_-98');
    expect(find.text('Share eq-new'), findsOneWidget);
  });

  testWidgets('new cold-start link resolves then pushes existing card once', (
    tester,
  ) async {
    final resolver = _Resolver(
      (_) async =>
          const ShareResolution(ShareResolutionStatus.resolved, 'eq-1'),
    );
    final h = await _start(
      tester,
      initialLink: 'https://open.prokat.auyltech.kz/e/$_shareId',
      resolver: resolver,
    );
    expect(resolver.calls, [_shareId]);
    expect(find.text('Share eq-1'), findsOneWidget);
    expect(h.recorder.opens.single.link.shareId, _shareId);
    expect(h.recorder.opens.single.via, ShareOpenVia.appLink);
    h.events()!.success('https://open.prokat.auyltech.kz/e/$_shareId');
    await tester.pumpAndSettle();
    expect(resolver.calls, [_shareId]);
    expect(h.recorder.opens, hasLength(1));
    h.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Main'), findsOneWidget);
    expect(h.router.canPop(), isFalse);
  });

  testWidgets(
    'new link waits for bootstrap and survives guest to login continuation',
    (tester) async {
      final resolver = _Resolver(
        (_) async =>
            const ShareResolution(ShareResolutionStatus.resolved, 'eq-1'),
      );
      final h = await _start(
        tester,
        route: AppStartupRouteState.loading,
        initialLink: 'https://open.prokat.auyltech.kz/e/$_shareId',
        resolver: resolver,
      );
      expect(resolver.calls, isEmpty);
      expect((await h.storage.readPendingOpen())?.link.shareId, _shareId);
      h.startup.setRoute(AppStartupRouteState.guest);
      await tester.pumpAndSettle();
      expect(find.text('Share eq-1'), findsOneWidget);
      await h.storage.saveOverlay(
        const EquipmentShareOverlay(path: '/e/eq-1', afterAuth: true),
      );
      h.router.pop();
      h.startup.setRoute(AppStartupRouteState.loading);
      await tester.pumpAndSettle();
      h.startup.setRoute(AppStartupRouteState.client);
      await tester.pumpAndSettle();
      expect(find.text('Share eq-1'), findsOneWidget);
      expect(h.recorder.opens, hasLength(1));
      expect(
        (await h.storage.readAcceptedOpen(equipmentId: 'eq-1'))?.link.shareId,
        _shareId,
      );
    },
  );

  testWidgets('warm link across background/resume notifications opens once', (
    tester,
  ) async {
    final resolver = _Resolver(
      (_) async =>
          const ShareResolution(ShareResolutionStatus.resolved, 'eq-2'),
    );
    final h = await _start(tester, resolver: resolver);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    h.events()!.success('https://open.prokat.auyltech.kz/e/$_shareId');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    h.startup.setRoute(AppStartupRouteState.owner);
    await tester.pumpAndSettle();
    expect(find.text('Share eq-2'), findsOneWidget);
    expect(h.recorder.opens, hasLength(1));
    expect(resolver.calls, [_shareId]);
  });

  testWidgets('out-of-order runtime resolution never opens the old card', (
    tester,
  ) async {
    const newerId = 'ZyXwVuTsRqPoNmLkJi_-98';
    final old = Completer<ShareResolution>();
    final newer = Completer<ShareResolution>();
    final resolver = _Resolver(
      (id) => id == _shareId ? old.future : newer.future,
    );
    final h = await _start(tester, resolver: resolver);
    h.events()!.success('https://open.prokat.auyltech.kz/e/$_shareId');
    await tester.pumpAndSettle();
    h.events()!.success('https://open.prokat.auyltech.kz/e/$newerId');
    await tester.pumpAndSettle();
    newer.complete(
      const ShareResolution(ShareResolutionStatus.resolved, 'eq-new'),
    );
    await tester.pumpAndSettle();
    old.complete(
      const ShareResolution(ShareResolutionStatus.resolved, 'eq-old'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Share eq-new'), findsOneWidget);
    expect(find.text('Share eq-old'), findsNothing);
    expect(h.recorder.opens.single.link.shareId, newerId);
    h.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Main'), findsOneWidget);
    expect(h.router.canPop(), isFalse);
  });

  testWidgets(
    'unavailable and temporary resolver outcomes do not strand loading screens',
    (tester) async {
      var result = ShareResolutionStatus.unavailable;
      final resolver = _Resolver((_) async => ShareResolution(result));
      final h = await _start(tester, resolver: resolver);
      h.events()!.success('https://open.prokat.auyltech.kz/e/$_shareId');
      await tester.pumpAndSettle();
      expect(find.text('Main'), findsOneWidget);
      expect(h.recorder.opens, isEmpty);
      expect(await h.storage.readPendingOpen(), isNull);
      result = ShareResolutionStatus.temporary;
      h.events()!.success(
        'https://open.prokat.auyltech.kz/e/ZyXwVuTsRqPoNmLkJi_-98',
      );
      await tester.pumpAndSettle();
      expect(find.text('Main'), findsOneWidget);
      expect(
        (await h.storage.readPendingOpen())?.link.shareId,
        'ZyXwVuTsRqPoNmLkJi_-98',
      );
      h.startup.setRoute(AppStartupRouteState.owner);
      await tester.pumpAndSettle();
      expect(resolver.calls, hasLength(2));
    },
  );

  testWidgets('public Web domain never navigates or invokes the resolver', (
    tester,
  ) async {
    final resolver = _Resolver(
      (_) async =>
          const ShareResolution(ShareResolutionStatus.resolved, 'eq-1'),
    );
    final h = await _start(tester, resolver: resolver);
    h.events()!.success('https://prokat.auyltech.kz/e/$_shareId');
    await tester.pumpAndSettle();
    expect(find.text('Main'), findsOneWidget);
    expect(h.recorder.opens, isEmpty);
    expect(resolver.calls, isEmpty);
  });

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
