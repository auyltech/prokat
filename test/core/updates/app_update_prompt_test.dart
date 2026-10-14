import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/updates/app_update_prompt.dart';
import 'package:prokat/core/updates/app_update_policy.dart';
import 'package:prokat/core/updates/emergency_update_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import '../../helpers/test_app_upgrader.dart';
import '../../helpers/fake_emergency_config_client.dart';

Future<GoRouter> _mount(
  WidgetTester tester,
  TestAppUpgrader upgrader, {
  String language = 'en',
  ValueNotifier<bool>? enabled,
  ValueNotifier<String?>? emergency,
  bool preinitialize = true,
}) async {
  upgrader.updateState(upgrader.state.copyWith(languageCodeOverride: language));
  if (preinitialize) await tester.runAsync(upgrader.initialize);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/e/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Equipment ${state.pathParameters['id']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (_, child) => ListenableBuilder(
        listenable: Listenable.merge([enabled, emergency]),
        builder: (_, _) => AppUpdatePrompt(
          navigatorKey: router.routerDelegate.navigatorKey,
          backButtonDispatcher: router.backButtonDispatcher,
          locale: Locale(language),
          enabled: enabled?.value ?? true,
          emergencyMinimum: emergency?.value,
          upgrader: upgrader,
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUp(() {
    resetUpgradePreferences();
  });

  for (final latest in ['1.0.1', '1.0.10', '1.0.0+19']) {
    _mobileTest('patch/build release $latest has no UI', (tester) async {
      final upgrader = TestAppUpgrader(
        TestUpgradeStore(availableVersion: latest),
      );
      addTearDown(upgrader.dispose);
      await _mount(tester, upgrader);
      expect(find.byType(AlertDialog), findsNothing);
      expect(upgrader.shouldDisplayUpgrade(), isFalse);
    });
  }

  for (final (latest, remote, store) in <(String?, String?, String?)>[
    ('2.0.0', null, null),
    ('1.0.1', '1.0.1', null),
    ('1.0.1', null, '1.0.1'),
    ('1.0.1', '1.0.1', '1.0.2'),
    ('1.0.1', '1.1.0', '1.0.1'),
    (null, '1.0.1', null),
  ]) {
    _mobileTest(
      'HARD latest=$latest remote=$remote store=$store cannot be bypassed',
      (tester) async {
        final minimum = ValueNotifier(remote);
        addTearDown(minimum.dispose);
        final upgrader = TestAppUpgrader(
          TestUpgradeStore(availableVersion: latest, minimum: store),
        );
        addTearDown(upgrader.dispose);
        final router = await _mount(tester, upgrader, emergency: minimum);
        expect(upgrader.policy, AppUpdatePolicy.hard);
        expect(find.byKey(const Key('upgrader_hard_dialog')), findsOneWidget);
        expect(find.text('LATER'), findsNothing);
        expect(find.text('IGNORE'), findsNothing);
        expect(find.text('UPDATE NOW'), findsOneWidget);
        await tester.tapAt(const Offset(5, 5));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(router.state.uri.path, '/');
        unawaited(router.push('/e/pending-share'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/e/pending-share');
        await tester.tap(find.text('UPDATE NOW'));
        await tester.pumpAndSettle();
        expect(upgrader.updateCalls, 1);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );
  }

  for (final initial in ['1.0.1', '1.1.0']) {
    _mobileTest(
      'real-time minimum escalates $initial safely with one dialog and releases back on rollback',
      (tester) async {
        final client = FakeEmergencyConfigClient();
        addTearDown(client.events.close);
        final controller = EmergencyMinimumController(
          platform: TargetPlatform.android,
          client: client,
          autoStart: false,
        );
        addTearDown(controller.dispose);
        await controller.start();
        final minimum = ValueNotifier<String?>(controller.state);
        addTearDown(minimum.dispose);
        final cancel = controller.addListener((value) => minimum.value = value);
        addTearDown(cancel);
        final upgrader = TestAppUpgrader(
          TestUpgradeStore(availableVersion: initial),
        );
        addTearDown(upgrader.dispose);
        final router = await _mount(tester, upgrader, emergency: minimum);
        final navigator = router.routerDelegate.navigatorKey.currentState;
        client.pending['min_supported_version_android'] = '1.0.1';
        client.events.add({'min_supported_version_android'});
        client.events.add({'min_supported_version_android'});
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
        expect(find.text('IGNORE'), findsNothing);
        unawaited(router.push('/e/eq-realtime'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/e/eq-realtime');
        expect(
          router.routerDelegate.navigatorKey.currentState,
          same(navigator),
        );
        expect(client.fetchCalls, 1);
        client.pending['min_supported_version_android'] = '';
        client.events.add({'min_supported_version_android'});
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('upgrader_hard_dialog')), findsNothing);
        expect(router.state.uri.path, '/e/eq-realtime');
        if (initial == '1.0.1') {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(router.state.uri.path, '/');
        }
      },
    );
  }

  _mobileTest(
    'emergency minimum bypasses a previous Ignore without resetting route',
    (tester) async {
      final minimum = ValueNotifier<String?>(null);
      addTearDown(minimum.dispose);
      final upgrader = TestAppUpgrader(TestUpgradeStore());
      addTearDown(upgrader.dispose);
      final router = await _mount(tester, upgrader, emergency: minimum);
      await tester.tap(find.text('IGNORE'));
      await tester.pumpAndSettle();
      minimum.value = '1.0.1';
      await tester.pump();
      await tester.pumpAndSettle();
      expect(upgrader.alreadyIgnoredThisVersion(), isTrue);
      expect(find.byKey(const Key('upgrader_hard_dialog')), findsOneWidget);
      expect(router.state.uri.path, '/');
    },
  );

  for (final version in [null, '0.9.0', '1.0.0']) {
    _mobileTest('store version $version does not prompt', (tester) async {
      final upgrader = TestAppUpgrader(
        TestUpgradeStore(availableVersion: version),
      );
      addTearDown(upgrader.dispose);
      await _mount(tester, upgrader);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });
  }

  _mobileTest(
    'normal widget initialization displays asynchronously loaded store version',
    (tester) async {
      final upgrader = TestAppUpgrader(TestUpgradeStore());
      addTearDown(upgrader.dispose);
      await _mount(tester, upgrader, preinitialize: false);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );

  test('production uses standard Android and iOS store adapters', () {
    final upgrader = PolicyAppUpgrader();
    addTearDown(upgrader.dispose);
    expect(
      upgrader.storeController.getUpgraderStore(TestUpgradeOS()),
      isA<UpgraderPlayStore>(),
    );
    expect(
      upgrader.storeController.getUpgraderStore(
        TestUpgradeOS(UpgraderOSType.ios),
      ),
      isA<UpgraderAppStore>(),
    );
    expect(upgrader.state.countryCodeOverride, 'KZ');
    expect(upgrader.state.minAppVersion, isNull);
    expect(upgrader.state.showOnlyMandatoryUpdates, isFalse);
    expect(upgrader.state.debugDisplayAlways, isFalse);
    expect(upgrader.state.debugDisplayOnce, isFalse);
  });

  _mobileTest('newer version prompts with all soft actions and safe defaults', (
    tester,
  ) async {
    final upgrader = TestAppUpgrader(TestUpgradeStore());
    addTearDown(upgrader.dispose);
    await _mount(tester, upgrader);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('IGNORE'), findsOneWidget);
    expect(find.text('LATER'), findsOneWidget);
    expect(find.text('UPDATE NOW'), findsOneWidget);
    expect(upgrader.blocked(), isFalse);
    expect(upgrader.state.minAppVersion, isNull);
    expect(upgrader.state.showOnlyMandatoryUpdates, isFalse);
    expect(upgrader.state.debugDisplayAlways, isFalse);
    expect(upgrader.state.debugDisplayOnce, isFalse);
    expect(upgrader.state.durationUntilAlertAgain, const Duration(days: 3));
  });

  for (final action in ['LATER', 'IGNORE', 'UPDATE NOW']) {
    _mobileTest('$action dismisses only the prompt and preserves route', (
      tester,
    ) async {
      final upgrader = TestAppUpgrader(TestUpgradeStore());
      addTearDown(upgrader.dispose);
      final router = await _mount(tester, upgrader);
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(router.state.uri.path, '/');
      if (action == 'IGNORE') {
        expect(upgrader.alreadyIgnoredThisVersion(), isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('userIgnoredVersion'), '1.1.0');
      }
      if (action == 'LATER') expect(upgrader.isTooSoon(), isTrue);
      if (action == 'UPDATE NOW') {
        expect(upgrader.updateCalls, 1);
        expect(
          upgrader.currentAppStoreListingURL,
          contains('com.auyltech.prokat'),
        );
      }
      expect(upgrader.shouldDisplayUpgrade(), isFalse);
    });
  }

  _mobileTest(
    'prompt waits for startup; toggling eligibility retains navigator',
    (tester) async {
      final ready = ValueNotifier(false);
      addTearDown(ready.dispose);
      final upgrader = TestAppUpgrader(TestUpgradeStore());
      addTearDown(upgrader.dispose);
      final router = await _mount(tester, upgrader, enabled: ready);
      expect(find.byType(AlertDialog), findsNothing);
      unawaited(router.push('/e/eq-1'));
      await tester.pumpAndSettle();
      final navigator = router.routerDelegate.navigatorKey.currentState;
      ready.value = true;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('LATER'));
      await tester.pumpAndSettle();
      ready.value = false;
      await tester.pumpAndSettle();
      expect(router.routerDelegate.navigatorKey.currentState, same(navigator));
      expect(router.state.uri.path, '/e/eq-1');
      expect(find.text('Equipment eq-1'), findsOneWidget);
    },
  );

  for (final action in ['LATER', 'IGNORE']) {
    _mobileTest(
      '$action callback cannot pop a warm-link route above the dialog',
      (tester) async {
        final upgrader = TestAppUpgrader(TestUpgradeStore());
        addTearDown(upgrader.dispose);
        final router = await _mount(tester, upgrader);
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, action),
        );
        unawaited(router.push('/e/eq-warm'));
        await tester.pumpAndSettle();
        button.onPressed!();
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/e/eq-warm');
        expect(find.text('Equipment eq-warm'), findsOneWidget);
        expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
      },
    );
  }

  _mobileTest('back dismisses the soft prompt and releases display guard', (
    tester,
  ) async {
    final upgrader = TestAppUpgrader(TestUpgradeStore());
    addTearDown(upgrader.dispose);
    await _mount(tester, upgrader);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester
          .state<UpgradeAlertState>(
            find.byWidgetPredicate((widget) => widget is UpgradeAlert).first,
          )
          .displayed,
      isFalse,
    );
  });

  for (final platform in [UpgraderOSType.android, UpgraderOSType.ios]) {
    for (final language in ['ru', 'kk', 'en']) {
      _mobileTest(
        '$platform uses package ID, KZ store and $language messages',
        (tester) async {
          final store = TestUpgradeStore();
          final upgrader = TestAppUpgrader(store, platform: platform);
          addTearDown(upgrader.dispose);
          await _mount(tester, upgrader, language: language);
          expect(store.lookups.single, (
            package: 'com.auyltech.prokat',
            country: 'KZ',
            language: language,
          ));
          final messages = AppUpgradeMessages(language);
          for (final text in [
            messages.title,
            messages.buttonTitleIgnore,
            messages.buttonTitleLater,
            messages.buttonTitleUpdate,
          ]) {
            expect(find.text(text), findsOneWidget);
          }
          expect(messages.releaseNotes, isNotEmpty);
          expect(
            upgrader.currentAppStoreListingURL,
            platform == UpgraderOSType.ios
                ? contains('id6817078475')
                : contains('com.auyltech.prokat'),
          );
        },
      );
    }
  }
}

void _mobileTest(String name, WidgetTesterCallback callback) => testWidgets(
  name,
  callback,
  variant: const TargetPlatformVariant({TargetPlatform.android}),
);
