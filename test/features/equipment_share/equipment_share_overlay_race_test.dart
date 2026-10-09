import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_bootstrap.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';
import 'package:prokat/features/equipment_share/equipment_share_open_recorder.dart';

import '../../helpers/recording_share_open_recorder.dart';

const _linksMethod = MethodChannel('com.llfbandit.app_links/messages');
const _linksEvents = EventChannel('com.llfbandit.app_links/events');
const _referrerChannel = MethodChannel(
  'com.chunkytofustudios.play_install_referrer',
);

String _key(String name) => Env.isLocal ? 'local_$name' : name;

String get _overlayKey => _key('equipment_share_overlay');

String get _referrerCheckedKey =>
    _key('equipment_share_install_referrer_checked');

String _overlayJson(String path, {bool afterAuth = false}) => jsonEncode(
  EquipmentShareOverlay(path: path, afterAuth: afterAuth).toJson(),
);

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

/// Holds overlay reads until [release], to stop a consume mid-flight.
class _GatedSecureStorage extends FlutterSecureStorage {
  Completer<void>? _gate;
  bool failReads = false;

  void hold() => _gate = Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final gate = _gate;
    if (gate != null &&
        (key == _overlayKey || key == _key('equipment_share_state'))) {
      await gate.future;
    }
    if (failReads) throw StateError('simulated storage read failure');
    return super.read(key: key);
  }
}

class _Harness {
  _Harness(this.container, this.router, this.sharePages, this.events);

  final ProviderContainer container;
  final GoRouter router;

  /// Page keys of every `/e/:id` page built, per equipment id. One push
  /// creates one page key, so the set size is the number of card opens.
  final Map<String, Set<ValueKey<String>>> sharePages;
  final MockStreamHandlerEventSink? Function() events;

  int opens(String id) => sharePages[id]?.length ?? 0;

  _FakeStartup get startup =>
      container.read(appStartupProvider.notifier) as _FakeStartup;
}

/// [hops] delays `getInitialLink` by that many microtask turns, which moves
/// the overlay write relative to the startup consume deterministically.
Future<_Harness> _start(
  WidgetTester tester, {
  String? initialLink,
  int hops = 0,
  AppStartupRouteState route = AppStartupRouteState.client,
  String initialLocation = AppRoutes.main,
  Map<String, String> storage = const {},
  FlutterSecureStorage? secureStorage,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    _referrerCheckedKey: '1',
    ...storage,
  });

  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_linksMethod, (call) async {
    for (var i = 0; i < hops; i++) {
      await Future<void>.value();
    }
    return call.method == 'getInitialLink' ? initialLink : null;
  });
  MockStreamHandlerEventSink? sink;
  messenger.setMockStreamHandler(
    _linksEvents,
    MockStreamHandler.inline(
      onListen: (_, events) {
        sink = events;
      },
    ),
  );
  messenger.setMockMethodCallHandler(_referrerChannel, (_) async => null);
  addTearDown(() {
    messenger.setMockMethodCallHandler(_linksMethod, null);
    messenger.setMockStreamHandler(_linksEvents, null);
    messenger.setMockMethodCallHandler(_referrerChannel, null);
  });

  final sharePages = <String, Set<ValueKey<String>>>{};
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.main,
        builder: (_, _) => const Scaffold(body: Text('Main')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: '/other',
        builder: (_, _) => const Scaffold(body: Text('Other')),
      ),
      GoRoute(
        path: '/e/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          sharePages.putIfAbsent(id, () => {}).add(state.pageKey);
          return Scaffold(body: Text('Share $id'));
        },
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(router),
      appStartupProvider.overrideWith((ref) => _FakeStartup(ref, route)),
      shareOpenRecorderProvider.overrideWithValue(RecordingShareOpenRecorder()),
      if (secureStorage != null)
        equipmentShareStorageProvider.overrideWithValue(
          EquipmentShareStorage(storage: secureStorage),
        ),
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

  return _Harness(container, router, sharePages, () => sink);
}

Future<String?> _storedOverlay() async =>
    (await EquipmentShareStorage().readOverlaySnapshot()).overlay?.path;

void main() {
  testWidgets(
    'share storage failure leaves normal app usable and later ingress can recover',
    (tester) async {
      final storage = _GatedSecureStorage();
      final h = await _start(tester, secureStorage: storage);
      storage.failReads = true;
      h.startup.setRoute(AppStartupRouteState.owner);
      await tester.pumpAndSettle();
      expect(find.text('Main'), findsOneWidget);
      h.router.go('/other');
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);
      storage.failReads = false;
      h.events()!.success('https://prokat-bfbec.web.app/e/eq-recovered');
      await tester.pumpAndSettle();
      expect(find.text('Share eq-recovered'), findsOneWidget);
      expect(h.opens('eq-recovered'), 1);
      expect(tester.takeException(), isNull);
    },
  );

  group('cold-start initial link timing', () {
    for (var hops = 0; hops <= 8; hops++) {
      testWidgets('opens the card exactly once, hops=$hops', (tester) async {
        final h = await _start(
          tester,
          initialLink: 'https://prokat-bfbec.web.app/e/eq-1',
          hops: hops,
        );

        expect(find.text('Share eq-1'), findsOneWidget);
        expect(h.opens('eq-1'), 1);
        expect(await _storedOverlay(), isNull);
      });
    }
  });

  testWidgets('overlay stored before startup opens once', (tester) async {
    final h = await _start(
      tester,
      storage: {_overlayKey: _overlayJson('/e/eq-1')},
    );

    expect(find.text('Share eq-1'), findsOneWidget);
    expect(h.opens('eq-1'), 1);
    expect(await _storedOverlay(), isNull);
  });

  testWidgets('legacy plain-uri overlay still opens once', (tester) async {
    final h = await _start(
      tester,
      storage: {_overlayKey: 'https://prokat-bfbec.web.app/e/eq-1'},
    );

    expect(h.opens('eq-1'), 1);
  });

  testWidgets('warm link after startup settled opens once', (tester) async {
    final h = await _start(tester);
    expect(h.opens('eq-2'), 0);

    h.events()!.success('https://prokat-bfbec.web.app/e/eq-2');
    await tester.pumpAndSettle();

    expect(find.text('Share eq-2'), findsOneWidget);
    expect(h.opens('eq-2'), 1);
  });

  testWidgets('pending link opens once across overlapping notifications', (
    tester,
  ) async {
    final h = await _start(
      tester,
      initialLink: 'https://prokat-bfbec.web.app/e/eq-1',
      route: AppStartupRouteState.loading,
    );
    expect(h.opens('eq-1'), 0);

    h.startup.setRoute(AppStartupRouteState.guest);
    h.startup.setRoute(AppStartupRouteState.client);
    h.startup.setRoute(AppStartupRouteState.owner);
    await tester.pumpAndSettle();

    expect(h.opens('eq-1'), 1);
  });

  testWidgets('later notifications and navigation do not reopen', (
    tester,
  ) async {
    final h = await _start(
      tester,
      initialLink: 'https://prokat-bfbec.web.app/e/eq-1',
      hops: 2,
    );
    expect(h.opens('eq-1'), 1);

    h.router.pop();
    await tester.pumpAndSettle();
    h.startup.setRoute(AppStartupRouteState.owner);
    h.startup.setRoute(AppStartupRouteState.client);
    await tester.pumpAndSettle();
    h.router.go('/other');
    await tester.pumpAndSettle();

    expect(h.opens('eq-1'), 1);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('empty storage: no navigation', (tester) async {
    final h = await _start(tester);

    expect(find.text('Main'), findsOneWidget);
    expect(h.sharePages, isEmpty);
  });

  testWidgets('corrupt overlay is cleared without navigation', (tester) async {
    final h = await _start(tester, storage: {_overlayKey: '{not json'});

    expect(find.text('Main'), findsOneWidget);
    expect(h.sharePages, isEmpty);
    expect(await _storedOverlay(), isNull);
  });

  group('afterAuth', () {
    testWidgets('client pushes the card once', (tester) async {
      final h = await _start(
        tester,
        storage: {_overlayKey: _overlayJson('/e/eq-3', afterAuth: true)},
      );

      expect(find.text('Share eq-3'), findsOneWidget);
      expect(h.opens('eq-3'), 1);
    });

    testWidgets('guest on landing cancels it', (tester) async {
      final h = await _start(
        tester,
        route: AppStartupRouteState.guest,
        storage: {_overlayKey: _overlayJson('/e/eq-3', afterAuth: true)},
      );

      expect(h.sharePages, isEmpty);
      expect(await _storedOverlay(), isNull);
    });

    testWidgets('guest on login keeps it until the account is ready', (
      tester,
    ) async {
      final h = await _start(
        tester,
        route: AppStartupRouteState.guest,
        initialLocation: AppRoutes.login,
        storage: {_overlayKey: _overlayJson('/e/eq-3', afterAuth: true)},
      );
      expect(h.sharePages, isEmpty);
      expect(await _storedOverlay(), isNotNull);

      h.startup.setRoute(AppStartupRouteState.client);
      h.router.go(AppRoutes.main);
      await tester.pumpAndSettle();

      expect(h.opens('eq-3'), 1);
      expect(await _storedOverlay(), isNull);
    });
  });

  testWidgets('consume requested while one is in flight is not dropped', (
    tester,
  ) async {
    final gated = _GatedSecureStorage();
    final h = await _start(tester, secureStorage: gated);
    final storage = h.container.read(equipmentShareStorageProvider);

    gated.hold();
    h.router.go('/other');
    await tester.pump();
    // Consume #1 is now blocked reading an empty overlay. The write queues
    // behind that read; the second router change asks for a consume while #1
    // is still in flight, and nothing triggers one afterwards.
    unawaited(
      storage.saveOverlay(
        const EquipmentShareOverlay(path: '/e/eq-5', afterAuth: false),
      ),
    );
    h.router.go(AppRoutes.main);
    await tester.pump();

    gated.release();
    await tester.pumpAndSettle();

    expect(find.text('Share eq-5'), findsOneWidget);
    expect(h.opens('eq-5'), 1);
    expect(await _storedOverlay(), isNull);
  });

  testWidgets('guest writer during an in-flight consume is not lost', (
    tester,
  ) async {
    final h = await _start(tester, route: AppStartupRouteState.guest);
    final storage = h.container.read(equipmentShareStorageProvider);

    // A router change starts a consume; the afterAuth write lands while it is
    // still in flight, exactly like GuestCreateBookingScreen writing before
    // `go(login)`.
    h.router.go('/other');
    await storage.saveOverlay(
      const EquipmentShareOverlay(path: '/e/eq-4', afterAuth: true),
    );
    await tester.pumpAndSettle();

    expect(await _storedOverlay(), isNotNull);
    expect(h.sharePages, isEmpty);

    h.startup.setRoute(AppStartupRouteState.client);
    await tester.pumpAndSettle();

    expect(h.opens('eq-4'), 1);
  });
}
