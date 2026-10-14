import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/updates/app_update_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import '../../helpers/test_app_upgrader.dart';

Future<GoRouter> _mount(
  WidgetTester tester,
  TestAppUpgrader upgrader, {
  String language = 'en',
  ValueNotifier<bool>? enabled,
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
      builder: (_, child) => enabled == null
          ? AppUpdatePrompt(
              navigatorKey: router.routerDelegate.navigatorKey,
              locale: Locale(language),
              enabled: true,
              upgrader: upgrader,
              child: child!,
            )
          : ValueListenableBuilder<bool>(
              valueListenable: enabled,
              builder: (_, ready, _) => AppUpdatePrompt(
                navigatorKey: router.routerDelegate.navigatorKey,
                locale: Locale(language),
                enabled: ready,
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
    final upgrader = SoftAppUpgrader();
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
    final upgrader = TestAppUpgrader(TestUpgradeStore(mandatory: true));
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
        expect(prefs.getString('userIgnoredVersion'), '2.0.0');
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
