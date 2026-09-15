import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    builder: (context, appChild) =>
        AppToastHost(child: appChild ?? const SizedBox.shrink()),
    home: Scaffold(body: child),
  );
}

Future<void> _pumpIn(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDimens.defaultAnimationDuration);
}

Future<void> _pumpOut(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows info success and error messages', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return Column(
              children: [
                TextButton(
                  onPressed: () => AppToast.show(message: 'Info msg'),
                  child: const Text('info'),
                ),
                TextButton(
                  onPressed: () => AppToast.show(
                    message: 'Success msg',
                    type: AppToastType.success,
                  ),
                  child: const Text('success'),
                ),
                TextButton(
                  onPressed: () => AppToast.show(
                    message: 'Error msg',
                    type: AppToastType.error,
                  ),
                  child: const Text('error'),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('info'));
    await _pumpIn(tester);
    expect(find.text('Info msg'), findsOneWidget);

    await tester.tap(find.text('success'));
    await _pumpIn(tester);
    expect(find.text('Success msg'), findsOneWidget);
    expect(find.text('Info msg'), findsNothing);

    await tester.tap(find.text('error'));
    await _pumpIn(tester);
    expect(find.text('Error msg'), findsOneWidget);
    expect(find.text('Success msg'), findsNothing);

    await _pumpOut(tester);
    expect(find.text('Error msg'), findsNothing);
  });

  testWidgets('supports multiline and long text', (tester) async {
    const long =
        'This is a very long toast message that should wrap across multiple '
        'lines without throwing and remain visible to the user.';
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => AppToast.show(
                message: 'Line one\nLine two\n$long',
                type: AppToastType.info,
              ),
              child: const Text('show'),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('show'));
    await _pumpIn(tester);
    expect(find.textContaining('Line one'), findsOneWidget);
    expect(find.textContaining('Line two'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _pumpOut(tester);
  });

  testWidgets('works in dark theme', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => AppToast.show(
                message: 'Dark toast',
                type: AppToastType.success,
              ),
              child: const Text('show'),
            );
          },
        ),
        theme: AppTheme.darkTheme,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('show'));
    await _pumpIn(tester);
    expect(find.text('Dark toast'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _pumpOut(tester);
  });

  testWidgets('appears above modal bottom sheet', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  useRootNavigator: true,
                  builder: (_) => const SizedBox(
                    height: 200,
                    child: Center(child: Text('sheet-body')),
                  ),
                );
              },
              child: const Text('open-sheet'),
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('open-sheet'));
    await tester.pumpAndSettle();
    expect(find.text('sheet-body'), findsOneWidget);

    AppToast.show(message: 'Above sheet', type: AppToastType.error);
    await _pumpIn(tester);
    expect(find.text('Above sheet'), findsOneWidget);
    expect(find.text('sheet-body'), findsOneWidget);

    await _pumpOut(tester);
  });

  testWidgets('can be dismissed by swiping down', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => AppToast.show(message: 'Swipe me'),
              child: const Text('show'),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('show'));
    await _pumpIn(tester);
    expect(find.text('Swipe me'), findsOneWidget);

    await tester.drag(find.text('Swipe me'), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsNothing);
  });

  test('app_toast.dart has no legacy theme or Material snack APIs', () {
    final source = File('lib/core/widgets/ui_kit/toasts/app_toast.dart')
        .readAsStringSync();
    expect(source.contains('theme/legacy'), isFalse);
    expect(RegExp(r'(?<![A-Za-z])Colors\.').hasMatch(source), isFalse);
    expect(source.contains('colorScheme'), isFalse);
    expect(source.contains('ScaffoldMessenger'), isFalse);
    expect(source.contains('SnackBar'), isFalse);
    expect(source.contains('showSnackBar'), isFalse);
  });
}
