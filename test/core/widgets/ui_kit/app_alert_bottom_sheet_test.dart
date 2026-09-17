import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('AppBottomSheet barrier dismisses when isDismissible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                unawaited(
                  AppBottomSheet.show<void>(
                    context,
                    title: 'Sheet',
                    contentBuilder: (_) => const Text('body'),
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Sheet'), findsNothing);
  });

  testWidgets('AppBottomSheet barrier does not dismiss when !isDismissible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                unawaited(
                  AppBottomSheet.show<void>(
                    context,
                    title: 'Locked',
                    isDismissible: false,
                    enableDrag: false,
                    contentBuilder: (_) => const Text('body'),
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('AppAlertBottomSheet primary returns true', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await AppAlertBottomSheet.show(
                  context,
                  title: 'Confirm?',
                  description: 'Details',
                  primaryLabel: 'Yes',
                  secondaryLabel: 'No',
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm?'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('AppAlertBottomSheet secondary returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                result = await AppAlertBottomSheet.show(
                  context,
                  title: 'Confirm?',
                  primaryLabel: 'Yes',
                  secondaryLabel: 'No',
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets(
    'non-dismissible AppAlertBottomSheet buttons still return results',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await AppAlertBottomSheet.show(
                    context,
                    title: 'Locked',
                    primaryLabel: 'OK',
                    secondaryLabel: 'Cancel',
                    isDismissible: false,
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('Locked'), findsOneWidget);
      expect(result, isNull);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    },
  );

  test('AppAlertBottomSheet source has no legacy import', () {
    final source = File(
      'lib/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart',
    ).readAsStringSync();
    expect(source.contains('theme/legacy'), isFalse);
  });
}
