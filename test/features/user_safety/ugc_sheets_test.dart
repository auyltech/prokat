import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/user_safety/models/report_reason.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/widgets/report_sheet.dart';
import 'package:prokat/features/user_safety/widgets/ugc_more_button.dart';

import 'user_safety_test_support.dart';

const _target = ReportTarget(ReportTargetType.equipment, 'eq-b');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Widget reportLauncher() {
    return Consumer(
      builder: (context, ref, _) => Scaffold(
        body: TextButton(
          onPressed: () => unawaited(
            ReportSheet.show(
              context,
              ref,
              target: _target,
              counterpartUserId: 'owner-b',
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
  }

  testWidgets('submit stays disabled until a reason is picked', (tester) async {
    final api = FakeUserSafetyApi();
    await tester.pumpWidget(
      testApp(overrides: userSafetyOverrides(api), home: reportLauncher()),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final submit = find.byKey(const ValueKey('report-submit'));
    expect(tester.widget<AppElevatedButton>(submit).onTap, isNull);

    await tester.tap(find.byKey(const ValueKey('report-reason-FRAUD')));
    await tester.pumpAndSettle();
    expect(tester.widget<AppElevatedButton>(submit).onTap, isNotNull);
  });

  testWidgets('sent report offers block; "Not now" does not block', (
    tester,
  ) async {
    final api = FakeUserSafetyApi();
    await tester.pumpWidget(
      testApp(overrides: userSafetyOverrides(api), home: reportLauncher()),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-reason-SPAM')));
    await tester.enterText(find.byType(TextField), 'fake listing');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pumpAndSettle();

    expect(api.reportCalls.single.$2, ReportReason.spam);
    expect(api.reportCalls.single.$3, 'fake listing');
    expect(find.text('Not now'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(api.blockCalls, isEmpty);
  });

  testWidgets('failed report keeps the sheet open', (tester) async {
    final api = FakeUserSafetyApi()..reportErrorCode = 'VALIDATION_ERROR';
    await tester.pumpWidget(
      testApp(overrides: userSafetyOverrides(api), home: reportLauncher()),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('report-reason-OTHER')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('report-submit')), findsOneWidget);
    expect(find.text('Not now'), findsNothing);
  });

  testWidgets('more button opens Report + Block, confirm blocks once', (
    tester,
  ) async {
    final api = FakeUserSafetyApi();
    var blockedCallbacks = 0;
    await tester.pumpWidget(
      testApp(
        overrides: userSafetyOverrides(api),
        home: Scaffold(
          body: UgcMoreButton(
            counterpartUserId: 'owner-b',
            counterpartName: 'Owner B',
            reportTarget: _target,
            onBlocked: () => blockedCallbacks++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ugc-more-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ugc-action-report')), findsOneWidget);
    expect(find.byKey(const ValueKey('ugc-action-unblock')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ugc-action-block')));
    await tester.pumpAndSettle();
    expect(find.text('Block this user?'), findsOneWidget);
    await tester.tap(find.text('Block').last);
    await tester.pumpAndSettle();

    expect(api.blockCalls, ['owner-b']);
    expect(blockedCallbacks, 1);
  });

  testWidgets('blocked-by-me shows Unblock instead of Block', (tester) async {
    final api = FakeUserSafetyApi();
    await tester.pumpWidget(
      testApp(
        overrides: userSafetyOverrides(api),
        home: const Scaffold(
          body: UgcMoreButton(
            counterpartUserId: 'owner-b',
            counterpartName: 'Owner B',
            reportTarget: _target,
            isBlockedByMe: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ugc-more-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ugc-action-block')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ugc-action-unblock')));
    await tester.pumpAndSettle();
    expect(api.unblockCalls, ['owner-b']);
  });

  testWidgets('more button is hidden for own content, guests, empty id', (
    tester,
  ) async {
    Future<void> pump({required String? id, bool signedIn = true}) {
      return tester.pumpWidget(
        KeyedSubtree(
          key: UniqueKey(),
          child: testApp(
            overrides: userSafetyOverrides(
              FakeUserSafetyApi(),
              signedIn: signedIn,
            ),
            home: Scaffold(
              body: UgcMoreButton(
                counterpartUserId: id,
                counterpartName: '',
                reportTarget: _target,
              ),
            ),
          ),
        ),
      );
    }

    await pump(id: testCurrentUserId);
    expect(find.byKey(const ValueKey('ugc-more-button')), findsNothing);
    await pump(id: '');
    expect(find.byKey(const ValueKey('ugc-more-button')), findsNothing);
    await pump(id: null);
    expect(find.byKey(const ValueKey('ugc-more-button')), findsNothing);
    await pump(id: 'owner-b', signedIn: false);
    expect(find.byKey(const ValueKey('ugc-more-button')), findsNothing);
    await pump(id: 'owner-b');
    expect(find.byKey(const ValueKey('ugc-more-button')), findsOneWidget);
  });
}
