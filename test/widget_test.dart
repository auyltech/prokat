import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';

void main() {
  testWidgets('AppElevatedButton displays its label and handles taps', (
    WidgetTester tester,
  ) async {
    var wasPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppElevatedButton(
            title: 'Continue',
            onTap: () {
              wasPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(wasPressed, isTrue);
  });
}
