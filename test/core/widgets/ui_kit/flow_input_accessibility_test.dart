import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

void main() {
  testWidgets('large budget text and multiline action stay inside controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController(text: '25000');
    addTearDown(controller.dispose);
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ProkatFlowScope(
            palette: ProkatFlowPalette.light,
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppTextField(
                    controller: controller,
                    textStyle: const TextStyle(fontSize: 24),
                    prefix: const Text('₸'),
                  ),
                  const SizedBox(height: 16),
                  ProkatFlowPrimaryButton(
                    title: 'Отправить владельцам',
                    onPressed: () => taps++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final editable = tester.getRect(find.byType(EditableText));
    expect(editable.height, greaterThanOrEqualTo(48));
    final action = tester.getRect(find.byType(ProkatFlowPrimaryButton));
    final label = tester.getRect(find.text('Отправить владельцам'));
    expect(action.contains(label.topLeft), isTrue);
    expect(action.contains(label.bottomRight), isTrue);
    await tester.enterText(find.byType(TextField), '17000');
    expect(controller.text, '17000');
    await tester.tap(find.text('Отправить владельцам'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading action blocks duplicate taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ProkatFlowPrimaryButton(
            title: 'Send',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ProkatFlowPrimaryButton));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
